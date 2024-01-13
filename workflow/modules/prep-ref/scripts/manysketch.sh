#!/bin/bash
source ~/.bashrc
mamba activate branchwater
input=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/sketch_file/genome_info_${1}.csv
output=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/sketch/ref_sketch_${1}.zip
index21=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/index/ref_sketch_${1}.21.sbt
index31=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/index/ref_sketch_${1}.31.sbt
index51=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/index/ref_sketch_${1}.51.sbt
sourmash scripts manysketch -p k=21,k=31,k=51,scaled=1000,abund -c 16 -o $output $input

sourmash scripts index -o $index21 -k 21 -s 1000 -c 16 $output

sourmash scripts index -o $index31 -k 21 -s 1000 -c 16 $output

sourmash scripts index -o $index51 -k 21 -s 1000 -c 16 $output