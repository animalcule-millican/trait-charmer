import glob
import os
import pickle
import random


configfile: "/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/process-ref/config.yml"
workdir: config["working_directory"]

#def get_refs(config):
#    refs = []
#    for file in glob.glob(config["reference_genome_path"] + "/*.fna.gz"):
#        refs.append(file)
#    return refs

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

#ref_list = get_refs(config)
#ref_names = [os.path.basename(x).split("genomic")[0][:-1] for x in ref_list]

wildcard_constraints:
    ref_db_path = config["reference_database_path"],
    ref_db = "|".join(config["reference_database"]),
    pgp_db_path = config["pgp_database_path"],
    pgp_db = "|".join(config["pgp_database"]),
    metagenome_path = config["metagenome_path"],
    metagenome = "|".join(config["metagenome"]),
    taxa = "|".join(config["taxa"]),
    taxa_path = config["taxa_sketch_path"],
    ref_sk_path = config["reference_sketch_path"],
    ref_sk = "|".join(config["reference_sketch"]),
    #ref_genome = "|".join(ref_list),
    #ref_name = "|".join(ref_names),
    refdir = config["reference_directory"]


rule all:
    input:
        expand("/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/pgpt_counts/{ref_db}-{pgp_db}.counts.txt", ref_db=config["reference_database"], pgp_db=config["pgp_database"]),
        expand("{metagenome_path}/gather/{metagenome}-{taxa}.csv", metagenome=config["metagenome"], taxa=config["taxa"], metagenome_path=config["metagenome_path"]),
        expand("{metagenome_path}/gather/{metagenome}-{ref_sk}-bact_arch.csv", metagenome=config["metagenome"], ref_sk=config["reference_sketch"], metagenome_path=config["metagenome_path"])

rule search_refs:
    input:
        query = config["reference_database_path"] + "/{ref_db}",
        target = config["pgp_database_path"] + "/{pgp_db}"
    output:
        "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/pgpt_counts/{ref_db}-{pgp_db}.counts.txt"
    params:
        tmpdir = create_tmpdir()
    threads: 24
    resources:
        mem_mb = 200000
    conda:
        "trait-mapper"
    shell:
        """
        export TMPDIR={params.tmpdir}
        mmseqs search {input.query} {input.target} $TMPDIR/result $TMPDIR/tmp -e 1.000E-05 --start-sens 1 --sens-steps 3 -s 7 --db-load-mode 3 --threads {threads} --remove-tmp-files 1
        mmseqs filterdb $TMPDIR/result $TMPDIR/bestDB --extract-lines 1 --threads {threads}
        mmseqs convertalis {input.query} {input.target} $TMPDIR/bestDB {output} --format-mode 0 --db-load-mode 3 --format-output query,qheader,qseq,target,theader,tseq,pident,evalue --threads {threads}
        rm -rf {params.tmpdir}
        """   

rule sketch_metagenome:
    input:
        "{metagenome_path}/{metagenome}.filter-METAGENOME.fastq.gz"
    output:
        "{metagenome_path}/sketch/{metagenome}.sig.gz"
    conda:
        "branchwater"
    threads: 1
    resources:
        mem_mb = 10000
    shell:
        """
        sourmash sketch dna {input} -o {output} -p k=21,k=31,k=51,scaled=1000,abund --name {wildcards.metagenome}
        """

rule gather_taxa:
    input:
        sample = config["metagenome_path"] + "/sketch/{metagenome}.sig.gz",
        ref = config["taxa_sketch_path"] + "/{taxa}_sigs.zip"
    output:
        config["reference_directory"] + "/jgi_metagenomes/gather/{metagenome}-{taxa}.csv"
    params:
        kmer = 31
    threads: 24
    resources:
        mem_mb = 72000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts fastgather -o $TMPDIR/fastgather.csv -t 10000 -k 31 -c {threads} {input.sample} {input.ref}
        sourmash gather {input.sample} {input.ref} --picklist $TMPDIR/fastgather.csv:match_name:ident -o {output} -k {params.kmer} --threshold-bp 10000
        """

rule gather_refs:
    input:
        sample = config["metagenome_path"] + "/sketch/{metagenome}.sig.gz",
        ref = config['reference_sketch_path'] + "/{ref_sk}.zip"
    output:
        config["metagenome_path"] + "/gather/{metagenome}-{ref_sk}-bact_arch.csv"
    params:
        kmer = 31
    threads: 24
    resources:
        mem_mb = 72000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts fastgather -o $TMPDIR/fastgather.csv -t 10000 -k 31 -c {threads} {input.sample} {input.ref}
        sourmash gather {input.sample} {input.ref} --picklist $TMPDIR/fastgather.csv:match_name:ident -o {output} -k {params.kmer} --threshold-bp 10000
        """
