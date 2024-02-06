import os
import glob
import random
import pickle

configfile: "/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/gather-genomes/gather_genome_config.yml"
workdir: config["working_directory"]

def get_genome_files(config):
    files = glob.glob(f"{config['reference_directory']}/jgi_metagenomes/sketch/*.sig.gz")
    file_names = [os.path.basename(file).replace(".sig.gz", "") for file in files]
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
sample_names = get_genome_files(config)

wildcard_constraints:
    class_taxa = "|".join(config["class_taxa"]),
    database = "|".join(config["database"]),
    refdir = config["reference_directory"],
    index = "|".join(config["index"]),
    genome_index = "|".join(config["genome_file_index"]),
    ref_path = "|".join(config["reference_file_path"]),
    sample_name = "|".join(sample_names),
    target_database = "|".join(config["target_database"])
    #annotation_database = "|".join(config["annotation_database"])

rule all:
    input:
        expand("{refdir}/gather/{sample_name}_{index}_k{kmer}.gather.csv", refdir=config["reference_directory"], sample_name=sample_names, kmer=config["kmers"], index=config["index"]),
        expand("{refdir}/taxonomy/metagenome/{sample_name}_{index}_k{kmer}.csv", refdir=config["reference_directory"], sample_name=sample_names, kmer=config["kmers"], index=config["index"]),
        expand("{refdir}/gather/{sample_name}_{class_taxa}_k{kmer}.gather.csv", refdir=config["reference_directory"], sample_name=sample_names, kmer=config["kmers"], class_taxa=config["class_taxa"]),
        expand("{refdir}/taxonomy/metagenome/{sample_name}_{class_taxa}_k{kmer}.csv", refdir=config["reference_directory"], sample_name=sample_names, kmer=config["kmers"], class_taxa=config["class_taxa"])

rule fastgather:
    input:
        sample = "{refdir}/jgi_metagenomes/sketch/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/ref_sketch_{index}.zip"
    output:
        "{refdir}/gather/{sample_name}_{index}_k{kmer}.fastgather.csv"
    threads: 16
    resources:
        mem_mb = 30000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts fastgather -o {output} -t 10000 -k {wildcards.kmer} -c {threads} {input.sample} {input.ref}
        """

rule gather:
    input:
        sample = "{refdir}/jgi_metagenomes/sketch/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/ref_sketch_{index}.zip",
        gather = "{refdir}/gather/{sample_name}_{index}_k{kmer}.fastgather.csv"
    output:
        "{refdir}/gather/{sample_name}_{index}_k{kmer}.gather.csv"
    threads: 1
    resources:
        mem_mb = 20000
    conda:
        "branchwater"
    shell:
        """
        sourmash gather {input.sample} {input.ref} --picklist {input.gather}:match_name:ident -o {output} -k {wildcards.kmer} --threshold-bp 10000
        """

rule taxonomy:
    input:
        gather = "{refdir}/gather/{sample_name}_{index}_k{kmer}.gather.csv",
        lin = config["lineage_database"]
    output:
        "{refdir}/taxonomy/metagenome/{sample_name}_{index}_k{kmer}.csv"
    threads: 1
    resources:
        mem_mb = 20480
    conda:
        "branchwater"
    shell:
        """
        sourmash tax metagenome --gather {input.gather} --taxonomy {input.lin} --keep-full-identifiers > {output}
        """

rule taxa_fastgather:
    input:
        sample = "{refdir}/jgi_metagenomes/sketch/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/{class_taxa}_sigs.zip"
    output:
        "{refdir}/gather/{sample_name}_{class_taxa}_k{kmer}.fastgather.csv"
    threads: 16
    resources:
        mem_mb = 30000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts fastgather -o {output} -t 10000 -k {wildcards.kmer} -c {threads} {input.sample} {input.ref}
        """

rule taxa_gather:
    input:
        sample = "{refdir}/jgi_metagenomes/sketch/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/{class_taxa}_sigs.zip",
        gather = "{refdir}/gather/{sample_name}_{class_taxa}_k{kmer}.fastgather.csv"
    output:
        "{refdir}/gather/{sample_name}_{class_taxa}_k{kmer}.gather.csv"
    threads: 1
    resources:
        mem_mb = 20000
    conda:
        "branchwater"
    shell:
        """
        sourmash gather {input.sample} {input.ref} --picklist {input.gather}:match_name:ident -o {output} -k {wildcards.kmer} --threshold-bp 10000
        """

rule taxa_taxonomy:
    input:
        gather = "{refdir}/gather/{sample_name}_{class_taxa}_k{kmer}.gather.csv",
        lin = config["lineage_database"]
    output:
        "{refdir}/taxonomy/metagenome/{sample_name}_{class_taxa}_k{kmer}.csv"
    threads: 1
    resources:
        mem_mb = 20480
    conda:
        "branchwater"
    shell:
        """
        sourmash tax metagenome --gather {input.gather} --taxonomy {input.lin} --keep-full-identifiers > {output}
        """