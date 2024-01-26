#!/bin/bash
source ~/.bashrc
mamba activate trait-mapper
source random_directory.sh
export FILE_DIR=$TMPDIR
export dir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database
export input=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files/$1
#export files=$(cat $input)
#export Bname=$(basename -s .txt $input)
export DB=$dir/${1}_db
#rm -rf $TMPDIR/tmp

while read file; do
    gunzip -c $file >> $FILE_DIR/genomes.fna
done < $input

mmseqs createdb $FILE_DIR/genomes.fna $DB
mmseqs createindex $DB $TMPDIR/tmp --search-type 2 --translation-table 11 --threads 12 --remove-tmp-files 1



#create_dbs()
#{
#    source random_directory.sh
#    name=$(basename -s .fna.gz $1)
#    db=$TMPDIR/${name}_db
#    echo $TMPDIR >> $FILE_DIR/tmp_dirs.txt
#    echo $name >> $FILE_DIR/names.txt
#    echo $db >> $FILE_DIR/db.txt
#    mmseqs createdb $1 $db
#}

#export -f create_dbs
# Run create_dbs in parallel for each line of the input file
#cat $input | parallel -j 8 create_dbs

# Get the first file
#file_1=$(cat /home/glbrc.org/millican/TMPDIR/open-leopard/db.txt | head -n 1)
#file_2=$(cat /home/glbrc.org/millican/TMPDIR/open-leopard/db.txt | head -n 2 | tail -n 1)
#mmseqs concatdbs $file_1 $file_2 $DB --preserve-keys 1 --threads 1
# Get the rest of the files
#rest_files=$(cat /home/glbrc.org/millican/TMPDIR/open-leopard/db.txt | tail -n +3)
#mmseqs mergedbs $DB $DB $rest_files --prefixes $prefix_names
#cat /home/glbrc.org/millican/TMPDIR/open-leopard/db.txt | tail -n +2 > /home/glbrc.org/millican/TMPDIR/open-leopard/other_files.txt
#prefix_names=$(paste -sd, /home/glbrc.org/millican/TMPDIR/open-leopard/names.txt)
# Merge the databases into one database
#DB=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/genome_files.aa.DB
#while read file; do
#    mmseqs mergedbs $DB $DB $file --prefixes $prefix_names
#done < /home/glbrc.org/millican/TMPDIR/open-leopard/other_files.txt


#mmseqs mergedbs $file_1 $DB $rest_files --prefixes $prefix_names
# Create the index
#mmseqs createindex $DB $FILE_DIR/tmp --search-type 2 --translation-table 11 --threads 8 --remove-tmp-files 1
# Remove the temporary files
#rm -rf $FILE_DIR/tmp

#while read tmpdir; do
#    rm -rf $tmpdir
#done < $FILE_DIR/tmp_dirs.txt

# # Delete all subdirectories created in the last 8 hours
#find $FILE_DIR -type d -cmin -480 -exec rm -rf {} \;