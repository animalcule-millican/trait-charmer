#!/bin/bash
source /home/glbrc.org/millican/.bashrc
#snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/prepare-process_reference_files.smk --profile HTCondor
snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/prepare-process_reference_files.smk --profile HTCondor --allowed-rules search_refs
#snakemake -s /home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/merge_ref_dbs.smk --profile HTCondor