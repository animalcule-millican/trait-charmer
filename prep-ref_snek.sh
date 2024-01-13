#!/bin/bash
source /home/glbrc.org/millican/.bashrc
snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/test.smk --profile HTCondor