#!/bin/bash
source ~/.bashrc

out=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/tmp/gtdb_genomes_reps.tar.gz
location="/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome"
extract="gtdb_genomes_reps_r214/database/*/*/*/*/*_genomic.fna.gz"

wget -O $out 'https://data.gtdb.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_genomes_reps.tar.gz'
out=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/tmp/gtdb_genomes_reps.tar.gz
location="/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome"
tar -xzf $out -C $location --strip-components=6