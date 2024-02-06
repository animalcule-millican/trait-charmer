#!/bin/bash
source ~/.bashrc
mamba activate branchwater

input_file=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_genomes/${1}_genome_files.csv
output=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/$1
sig_dir=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/$1/signatures

sourmash scripts manysketch -p k=21,k=31,k=51,scaled=1000,abund -c 16 -o $output $input_file

mkdir -p $sig_dir/k21 $sig_dir/k31 $sig_dir/k51

cd $sig_dir/k21
sourmash sig split --ksize 21  $output --extension .sig.gz
find ./ -name "*.sig.gz" -type f > $output/${1}_k21_sig_list.txt

cd $sig_dir/k31
sourmash sig split --ksize 31  $output --extension .sig.gz
find ./ -name "*.sig.gz" -type f > $output/${1}_k31_sig_list.txt

cd $sig_dir/k51
sourmash sig split --ksize 51  $output --extension .sig.gz
find ./ -name "*.sig.gz" -type f > $output/${1}_k51_sig_list.txt
