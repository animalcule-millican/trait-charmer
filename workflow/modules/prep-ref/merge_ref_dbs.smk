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
    genome_index = "|".join(config["genome_file_index"]),
    ref_path = "|".join(config["reference_file_path"]),
    ref_name = "|".join(ref_names),
    target_database = "|".join(config["target_database"])
    #annotation_database = "|".join(config["annotation_database"])

rule all:
    input:
        expand("{pgp_dir}/pgp_trait_db", pgp_dir = "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp"),


rule merge_dbs:
    input:
        comp = expand("{pgp_dir}/Competitive_Fitness_db", pgp_dir = "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp"),
        eco = expand("{pgp_dir}/Ecosystem_Service_db", pgp_dir = "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp"),
        col = expand("{pgp_dir}/Plant_Colonization_db", pgp_dir = "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp"),
        strs = expand("{pgp_dir}/Stress_Control_db", pgp_dir = "/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp"),
    output:
        db = "{pgp_dir}/pgp_trait_db",
        idx = "{pgp_dir}/pgp_trait_db.idx"
    params:
        tmpdir = create_tmpdir()
    threads: 24
    resources:
        mem_mb = 140000
    shell:
        """
        mmseqs mergedbs {input.comp} {output.db} {input.eco} {input.col} {input.strs}
        mmseqs createindex {output.db} {params.tmpdir}
        """