import os
import glob


def get_genome_files(wildcards):
    files = glob.glob(f"{wildcards.refdir}/genomes/*.fna.gz")
    file_names = [os.path.basename(file).replace("_genomic.fna.gz", "") for file in files]
    return file_names

ref_names = get_genome_files(wildcards)



##########################################################################
rule get_genomes:
    input:
        "{refdir}/pkl/{taxa}_assembly_summary.pkl"
    output:
        "{refdir}s/{taxa}_genomes.txt"
    threads: 8
    resources:
        mem_mb = 6000
    run:
        """
        import urllib.request
        import os
        import pickle
        import concurrent.futures
        import time
        import random
        import glob
        import urllib.error

        url_dict = {}
        
        def download_genome(data_list):
            success = False
            while success is False:
                try:
                    urllib.request.urlretrieve(data_list[0], data_list[1])
                    time.sleep(random.uniform(0.01, 0.4))
                    success = True
                except urllib.error.HTTPError as e:
                    if e.code == 429:  # Too Many Requests
                        print("Too many requests, sleeping for a bit...")
                        time.sleep(10)
                    else:
                        success = True
            return True

        with open("{input}", 'rb') as f:
            gen_dict = pickle.load(f)
        
        for key in gen_dict.keys():
            url_dict[key] = [gen_dict[key]['ftp'], gen_dict[key]['genome_path']

        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            executor.map(download_genome, url_dict.values())

        genome_list = glob.glob("{params.genome_path}/*.gz")
        with open("{output}", 'w') as out:
            for genome in genome_list:
                out.write(f"{genome}\n")
        """

rule fetch_ncbi: # checked: worked 2023-12-18 used refseq archaea refdir as args for script
    output:
        "{refdir}/pkl/{taxa}-{database}_genome_info_dict.pickle"
    params:
        refdir = config["reference_directory"]
    threads: 8
    resources:
        mem_mb=10000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/get-ref-assem.py {wildcards.database} {wildcards.taxa} {params.refdir}
        """

rule fetch_gtdb:
    output:
        "{refdir}/tmp/gtdb_genome_name_list.txt"
    params:
        refdir = config["reference_directory"]
    threads: 6
    resources:
        mem_mb=8000
    shell:
        """
        scripts/get_gtdb.sh {params.refdir}
        """

rule genome_list: # checked: worked 2023-12-18 used refdir as arg for script
    input:
        expand("{refdir}/pkl/{taxa}-{database}_genome_info_dict.pickle", taxa = config["taxa"], database = config["database"], refdir = config["reference_directory"]),
        "{refdir}/tmp/gtdb_genomes.tar.gz".format(refdir=config["reference_directory"]),
        "{refdir}/tmp/gtdb_gene.tar.gz".format(refdir=config["reference_directory"]),
        "{refdir}/tmp/gtdb_prot.tar.gz".format(refdir=config["reference_directory"])
    output:
        expand("{refdir}/sketch_file/genome_info_{index}.csv", refdir = config["reference_directory"], index = range(1,10))
    params:
        refdir = config["reference_directory"]
    threads: 1
    resources:
        mem_mb=1000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/genome-list.py {params.refdir}
        """

rule parse_gtdb_taxonomy:
    input:
        '{refdir}/tmp/{taxa}_taxonomy.tsv.gz'
    output:
        "{refdir}/taxonomy/{taxa}_gtdb_taxonomy.csv"
    threads: 1
    resources:
        mem_mb=4000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/parse_gtdb_metadata.py {input} {output}
        """

rule parse_ncbi_taxonomy:
    input:
        "{refdir}/pkl/{taxa}-{database}_genome_info_dict.pickle"
    output:
        "{refdir}/taxonomy/{taxa}-{database}_ncbi_taxonomy.csv"
    threads: 1
    resources:
        mem_mb = 8000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/parse_ncbi_taxonomy_taxidTools.py {input} {output}
        """

rule join_taxonomy:
    input:
        expand("{refdir}/taxonomy/{taxa}_gtdb_taxonomy.csv", refdir = config["reference_directory"], taxa = config["taxa"]),
        expand("{refdir}/taxonomy/{taxa}-{database}_ncbi_taxonomy.csv", refdir = config["reference_directory"], taxa = config["taxa"], database = config["database"]),
    output:
        "{refdir}/taxonomy/reference_taxonomy.csv"
    params:
        refdir = config["reference_directory"]
    threads: 1
    resources:
        mem_mb=1000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/join-taxonomy.py {params.refdir} {input}
        """



rule sketch_genomes:
    input:
        "{refdir}/sketch_file/genome_info_{index}.csv"
    output:
        "{refdir}/sketch/genome_sketch_{index}.zip"
    threads: 12
    resources:
        mem_mb=10000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts manysketch -o {output} -p k=21,scaled=1000,abund -c {threads} {input}
        """

rule create_search_database:
    input:
        "{refdir}/proteins/{reference_names}_protein.faa.gz"
    output:
        database = "{refdir}/search_database/{reference_names}_DB",
        index = "{refdir}/search_database/{reference_names}_DB.idx"
    params:
        tmpdir = create_tmpdir()
    threads: 4
    resources:
        mem_mb=10000
    conda:
        "prepare-reference"
    shell:
        """
        export TMPDIR={params.tmpdir}
        export MMSEQS_FORCE_MERGE=1
        mmseqs createdb {input} {output.database}
        mmseqs createindex {output.database} $TMPDIR/tmp --search-type 1 --threads {threads} --remove-tmp-files 1
        rm -rf {params.tmpdir}
        """

rule annotate:
    input:
        "{refdir}/search_database/{reference_names}_DB"
    output:
        "{refdir}/annotation/{reference_names}-{wildcards.annotation_database}.txt"
    params:
        annotation_directory = config["annotation_directory"],
        tmpdir = create_tmpdir()
    shell:
        """
        export target={params.annotation_directory}/{wildcards.annotation_database}/{wildcards.annotation_database}_DB
        mmseqs search {input} $target $TMPDIR/result $TMPDIR/tmp --start-sens 1 --sens-steps 3 -s 7 --db-load-mode 3 --merge-query 1 --threads {threads}
        mmseqs filterdb $TMPDIR/result $TMPDIR/bestDB --extract-lines 1 --threads {threads}
        mmseqs convertalis {input} $target $TMPDIR/bestDB {output} --format-mode 0 --db-load-mode 3 --format-output query,qheader,qseq,target,theader,tseq --threads {threads}
        """

rule bgc:
    input:
        "{refdir}/genomes/{reference_names}.fna.gz"
    output:
        "{refdir}/bgc/{reference_names}/{reference_names}.bgc.gbk",
        "{refdir}/bgc/{reference_names}/{reference_names}.bgc.tsv",
        "{refdir}/bgc/{reference_names}/{reference_names}.full.gbk",
        "{refdir}/bgc/{reference_names}/{reference_names}.pfam.tsv",
        "{refdir}/bgc/{reference_names}/{reference_names}.antismash.json"
    params:
        output = "{refdir}/bgc"
    threads: 4
    resources:
        mem_mb=12000
    conda:
        "deepbgc"
    shell:
        """
        filename=$(basename -s ".fna.gz" {input})
        deepbgc pipeline -d clusterfinder_retrained -d clusterfinder_original -d clusterfinder_geneborder -d deepbgc --output {params.output}/{wildcards.reference_names} --label clf_ret --label clf_og --label clf_gb --label deep -c product_activity -c product_class {input}
        """

rule generate_map:
    input:
        "{refdir}/bgc/{reference_names}/{reference_names}.bgc.gbk",
        "{refdir}/bgc/{reference_names}/{reference_names}.bgc.tsv",
        "{refdir}/bgc/{reference_names}/{reference_names}.full.gbk",
        "{refdir}/bgc/{reference_names}/{reference_names}.pfam.tsv",
        "{refdir}/bgc/{reference_names}/{reference_names}.antismash.json",
        "{refdir}/annotation/{reference_names}-{wildcards.annotation_database}.txt"
    output:
        "{refdir}/map_files/{reference_names}.pkl"
    params:
        refdir = config["reference_directory"]
    threads: 1
    resources:
        mem_mb=1000
    conda:
        "prepare-reference"
    shell:
        """
        echo $(head -n 1 {input[0]} | cut -f 1) > {output}
        """
   