#!/bin/bash
source ~/.bashrc
mamba activate branchwater

dir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/sketch_file
taxa=$1
sourmash scripts manysketch -p k=21,k=31,k=51,scaled=1000,abund -c 12 -o $dir/${taxa}_sigs.zip $dir/genome_info_${taxa}.csv
