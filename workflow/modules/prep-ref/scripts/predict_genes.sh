#!/bin/bash
source ~/.bashrc
mamba activate genepred
export input=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files/genome_file.${1}
export prodir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/protein
export gffdir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/gff

genes()
{
    filename=$(basename -s "genomic.fna.gz" "$1")
    filename=${filename%?}
    prodir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/prot
    gffdir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/gff
    pprodigal -a $prodir/${filename}.faa -f gff -i $1 -n -o $gffdir/${filename}.gff
    gzip $prodir/${filename}.faa
    gzip $gffdir/${filename}.gff
}

export -f genes

cat $input | parallel -j 12 genes

