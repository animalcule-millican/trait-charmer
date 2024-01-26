#!/bin/bash
source ~/.bashrc
mamba activate trait-mapper
source random_directory.sh
dir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database
#in_files=$(find /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome/${taxa} -name "*.fna.gz")
taxa=$1
mmseqs createdb /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome/${taxa}/*.fna/gz $dir/${taxa}_db
mmseqs createindex $dir/${taxa}_db $TMPDIR/tmp --search-type 2 --translation-table 11 --threads 8 --remove-tmp-files 1
