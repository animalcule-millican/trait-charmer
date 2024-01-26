#!/bin/bash
source ~/.bashrc
mamba activate trait-mapper
source random_directory.sh
dir=/home/glbrc.org/millican/repos/trait-mapper/reference_database/$1
out=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp
#in_files=$(find /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome/${taxa} -name "*.fna.gz")
taxa=$2
mmseqs createdb $dir/${taxa}.faa.gz $out/${taxa}_db
mmseqs createindex $out/${taxa}_db $TMPDIR/tmp --translation-table 11 --threads 8 --remove-tmp-files 1
