#!/bin/bash
source ~/.bashrc
/home/glbrc.org/millican/mambaforge/bin/snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/process-ref/process_references_metagenomes.smk --profile HTCondor