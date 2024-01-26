#!/bin/bash
source ~/.bashrc
mamba activate branchwater

/home/glbrc.org/millican/repos/trait-mapper/bin/moving_ref_genomes.py $1

export gfile=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/$1/genome_info_${1}.csv

if [[ -f "$gfile" ]]; then

    export input_file=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/genome_info_${1}.csv
    export output=/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/${1}_sigs.zip

    sourmash scripts manysketch -p k=21,k=31,k=51,scaled=1000,abund -c 16 -o $output $input_file

    mkdir -p /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k21 /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k31 /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k51

    cd /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k21
    sourmash sig split --ksize 21  $output --extension .sig.gz
    find ./ -name "*.sig.gz" -type f > /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/${1}_k21_sig_list.txt

    cd /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k31
    sourmash sig split --ksize 31  $output --extension .sig.gz
    find ./ -name "*.sig.gz" -type f > /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/${1}_k31_sig_list.txt

    cd /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/signatures/k51
    sourmash sig split --ksize 51  $output --extension .sig.gz
    find ./ -name "*.sig.gz" -type f > /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_signatures/${1}/${1}_k51_sig_list.txt

else
    echo "No $gfile found for $1"
fi