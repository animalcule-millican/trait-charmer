#!/bin/bash
source /home/glbrc.org/millican/.bashrc

gtdb_genomes="https://data.gtdb.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_genomes_reps.tar.gz"
atax="https://data.gtdb.ecogenomic.org/releases/latest/ar53_metadata.tsv.gz"
btax="https://data.gtdb.ecogenomic.org/releases/latest/bac120_metadata.tsv.gz"

wget -O $1/tmp/gtdb_genomes_reps.tar.gz $gtdb_genomes &
wait

wget -O $1/tmp/ar53_metadata.tsv.gz $atax &
wget -O $1/tmp/bac120_metadata.tsv.gz $btax &
wait

tar -xzf $1/tmp/gtdb_genomes_reps.tar.gz -C $1/genome --strip-components=6
wait

tar -tzf $1/tmp/gtdb_genomes_reps.tar.gz | while IFS= read -r file
do
    # Get the basename of each file and append it to the text file
    basename -s "_genomic.fna.gz" "$file" >> $1/tmp/gtdb_genome_name_list.txt
done