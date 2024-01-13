configfile: "/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/gather-genomes/gather_genome_config.yml"

rule fastgather:
    input:
        sample = "{refdir}/sigs/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/ref_sketch_{index}.zip"
    output:
        "{refdir}/gather/{sample_name}_k{kmer}.fastgather.csv"
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
        sample = "{refdir}/sigs/{sample_name}.sig.gz",
        ref = "{refdir}/sketch/ref_sketch_{index}.zip"
        gather = "{refdir}/gather/{sample_name}_k{kmer}.fastgather.csv"
    output:
        "{refdir}/gather/{sample_name}_k{kmer}.gather.csv"
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
        gather = "{refdir}/gather/{sample_name}_k{kmer}.gather.csv",
        lin = "{refdir}/lineage/reference.lineages.sqldb"
    output:
        "{output_directory}/taxonomy/{sample_name}_k{kmer}.csv"
    threads: 1
    resources:
        mem_mb = 20480
    conda:
        "branchwater"
    shell:
        """
        sourmash tax metagenome --gather {input.gather} --taxonomy {input.lin} --keep-full-identifiers > {output}
        """