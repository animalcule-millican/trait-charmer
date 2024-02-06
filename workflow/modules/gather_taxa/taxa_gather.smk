configfile: "/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/gather_taxa/gather_taxa_config.yml"

rule fastgather:
    input:
        sample = "{output_directory}/sigs/{sample_name}.sig.gz",
        ref = expand("{sourmash_directory}/reference/{{taxa}}-k{{kmer}}.zip", sourmash_directory = config["sourmash_directory"])
    output:
        "{output_directory}/gather/{sample_name}_k{kmer}.{taxa}.fastgather.csv"
    params:
        kmer = "{kmer}",
        taxa = "{taxa}",
    threads: 12
    resources:
        mem_mb = 20000
    conda:
        "branchwater"
    shell:
        """
        sourmash scripts fastgather -o {output} -t 10000 -k {params.kmer} -c {threads} {input.sample} {input.ref}
        """

rule gather:
    input:
        sample = "{output_directory}/sigs/{sample_name}.sig.gz",
        ref = expand("{sourmash_directory}/reference/{{taxa}}-k{{kmer}}.zip", sourmash_directory = config["sourmash_directory"]),
        gather = "{output_directory}/gather/{sample_name}_k{kmer}.{taxa}.fastgather.csv"
    output:
        "{output_directory}/gather/{sample_name}_k{kmer}.{taxa}.csv"
    params:
        kmer = "{kmer}",
        taxa = "{taxa}",
    threads: 12
    resources:
        mem_mb = 20000
    conda:
        "branchwater"
    shell:
        """
        sourmash gather {input.sample} {input.ref} --picklist {input.gather}:match_name:ident -o {output} -k {params.kmer} --threshold-bp 10000
        """

rule taxonomy:
    input:
        gather = "{output_directory}/gather/{sample_name}_k{kmer}.{taxa}.csv",
        lin = config["sourmash_directory"] + "/lineage/{taxa}.lineages.sqldb"
    output:
        "{output_directory}/taxonomy/{sample_name}_k{kmer}.{taxa}.csv"
    threads: 1
    resources:
        mem_mb = 20480
    conda:
        "branchwater"
    shell:
        """
        sourmash tax metagenome --gather {input.gather} --taxonomy {input.lin} --keep-full-identifiers > {output}
        """