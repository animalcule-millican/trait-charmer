#!/bin/bash
source /home/glbrc.org/millican/.bashrc

snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/gather-genomes/genome_gather.smk --profile HTCondor
