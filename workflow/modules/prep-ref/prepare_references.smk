import os
import glob
import random
import pickle

configfile: "/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/prep-ref-config.yml"
workdir: config["working_directory"]

def get_genome_files(config):
    files = glob.glob(f"{config['reference_directory']}/genomes/*.fna.gz")
    file_names = [os.path.basename(file).replace("_genomic.fna.gz", "") for file in files]
    return file_names

def create_tmpdir():
    with open("/home/glbrc.org/millican/repos/metagenome_snakemake/etc/adj-aml.pkl", 'rb') as f:
        adj, aml = pickle.load(f)
    temp_dir_base = "/home/glbrc.org/millican/TMPDIR"    # Replace with the base path for temporary directories
    # Construct the temporary directory path
    tmpdir = os.path.join(temp_dir_base, f"{random.choice(adj)}-{random.choice(aml)}")
    # Check if the directory exists, and find a new combination if it does
    while os.path.exists(tmpdir):
        tmpdir = os.path.join(temp_dir_base, f"{random.choice(adj)}-{random.choice(aml)}")
    # Once we find a combination that does not already exist
    # Create the temporary directory
    os.makedirs(tmpdir, exist_ok=True)
    return tmpdir

def get_reference_names(config):
    refdir = config["reference_directory"]
    gdir = os.path.join(refdir, "genomes")
    g_files = []
    for file in glob.glob(os.path.join(gdir, "*.fna.gz")):
        name_file = os.path.basename(file).replace(".fna.gz", "")
        g_files.append(name_file)
    return g_files

#g_files = get_reference_names(config)
ref_names = get_genome_files(config)

wildcard_constraints:
    taxa = "|".join(config["taxa"]),
    database = "|".join(config["database"]),
    refdir = config["reference_directory"],
    index = "|".join(config["index"]),
    ref_path = "|".join(config["reference_file_path"]),
    ref_name = "|".join(ref_names),
    target_database = "|".join(config["target_database"])
    #annotation_database = "|".join(config["annotation_database"])

rule all:
    input:
        expand("{refdir}/pgpt_counts/{ref_name}-pgpt_counts.txt", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/taxonomy/reference_taxonomy.csv", refdir = config["reference_directory"]),
        expand("{refdir}/sketch_file/genome_info_{index}.csv", refdir = config["reference_directory"], index = config["index"]),
        expand("{refdir}/sketch/ref_sketch_{index}.zip", refdir = config["reference_directory"], index = config["index"]),
        expand("{refdir}/database/{ref_name}_DB", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/deepbgc/{ref_name}.bgc.gbk", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/deepbgc/{ref_name}.bgc.tsv", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/deepbgc/{ref_name}.full.gbk", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/deepbgc/{ref_name}.pfam.tsv", refdir = config["reference_directory"], ref_name = ref_names),
        expand("{refdir}/deepbgc/{ref_name}.antismash.json", refdir = config["reference_directory"], ref_name = ref_names)
        
rule get_reports:
    output:
        "{refdir}/pkl/{taxa}-{database}_assembly_summary.pkl"
    threads: 1
    resources:
        mem_mb = 4000
    shell:
        """
        scripts/pickle_assembly_reports.py {wildcards.taxa} {output} {wildcards.database}
        """

rule get_ncbi_files:
    input:
        "{refdir}/pkl/{taxa}-{database}_assembly_summary.pkl"
    output:
        "{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl"
    params:
        ref = config["reference_file_path"]
    threads: 3
    resources:
        mem_mb = 6000
    shell:
        """
        scripts/get_ftp_files.py {input} {params.ref} {output} {threads}
        """

rule fetch_gtdb:
    output:
        "{refdir}/tmp/gtdb_genome_name_list.txt"
    params:
        refdir = config["reference_directory"]
    threads: 3
    resources:
        mem_mb=8000
    shell:
        """
        scripts/get_gtdb.sh {params.refdir}
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
        "{refdir}/pkl/{taxa}-{database}_assembly_summary.pkl"
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

rule genome_list: # checked: worked 2023-12-18 used refdir as arg for script
    input:
        expand("{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl", taxa = config["taxa"], database = config["database"], refdir = config["reference_directory"]),
        "{refdir}/tmp/gtdb_genomes.tar.gz".format(refdir=config["reference_directory"]),
        "{refdir}/tmp/gtdb_gene.tar.gz".format(refdir=config["reference_directory"]),
        "{refdir}/tmp/gtdb_prot.tar.gz".format(refdir=config["reference_directory"])
    output:
        expand("{refdir}/sketch_file/genome_info_{index}.csv", index = config["index"], refdir = config["reference_directory"])
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

rule sketch_refs:
    input:
        genome_list = "{refdir}/sketch_file/genome_info_{index}.csv"
    output:
        "{refdir}/sketch/ref_sketch_{index}.zip"
    conda:
        "branchwater"
    threads: 12
    resources:
        mem_mb=30000
    shell:
        """
        sourmash scripts manysketch -p k=21,scaled=1000,abund -c {threads} -o {output} {input.genome_list}
        """

rule ref_db:
    input:
        genome = "{refdir}/genomes/{ref_name}.fna.gz",
        ncbi = "{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl",
        gtdb = "{refdir}/tmp/gtdb_genome_name_list.txt"
    output:
        "{refdir}/database/{ref_name}_DB"
    params:
        tmpdir = create_tmpdir()
    threads: 4
    resources:
        mem_mb = 20000
    conda:
        "trait-mapper"
    shell:
        """
        export TMPDIR={params.tmpdir}
        mmseqs createdb {input.genome} {output}
        mmseqs createindex {output} $TMPDIR/tmp --search-type 2 --translation-table 11 --threads {threads} --remove-tmp-files 1
        rm -rf {params.tmpdir}
        """

rule search_refs:
    input:
        "{refdir}/database/{ref_name}_DB"
    output:
        "{refdir}/pgpt_counts/{ref_name}-pgpt_counts.txt"
    params:
        target = "{refdir}/database/pgp/{target_database}_db",
        tmpdir = create_tmpdir()
    threads: 8
    resources:
        mem_mb = 60000
    conda:
        "trait-mapper"
    shell:
        """
        export TMPDIR={params.tmpdir}
        mmseqs search {input} {params.target} $TMPDIR/result $TMPDIR/tmp -e 1.000E-05 --start-sens 1 --sens-steps 3 -s 7 --db-load-mode 3 --threads {threads} --remove-tmp-files 1
        mmseqs filterdb $TMPDIR/result $TMPDIR/bestDB --extract-lines 1 --threads {threads}
        mmseqs convertalis {input} {params.target} $TMPDIR/bestDB {output} --format-mode 0 --db-load-mode 3 --format-output query,qheader,qseq,target,theader,tseq,pident,evalue --threads {threads}
        rm -rf {params.tmpdir}
        """   
    
rule deepbgc:
    input: 
        "{refdir}/genomes/{ref_name}.fna.gz"
    output:
        "{refdir}/deepbgc/{ref_name}.bgc.gbk",
        "{refdir}/deepbgc/{ref_name}.bgc.tsv",
        "{refdir}/deepbgc/{ref_name}.full.gbk",
        "{refdir}/deepbgc/{ref_name}.pfam.tsv",
        "{refdir}/deepbgc/{ref_name}.antismash.json"
    params:
        "{refdir}/deepbgc/{ref_name}"
    threads: 8
    resources:
        mem_mb = 60000
    conda:
        "deepbgc"
    shell:
        """
        deepbgc pipeline -d clusterfinder_retrained -d clusterfinder_original -d clusterfinder_geneborder -d deepbgc --output {params} --label clf_ret --label clf_og --label clf_gb --label deep -c product_activity -c product_class {input}
        """