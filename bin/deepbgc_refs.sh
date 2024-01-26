#!/bin/bash
source ~/.bashrc
mamba activate deepbgc

export input=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files/$1
export dir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/deepbgc

while read genome; do
    gen_name=$(basename -s genomic.fna.gz $genome)
    gen_name=${gen_name%?}
    if [ ! -d $dir/$gen_name ]; then
        mkdir $dir/$gen_name
    fi
    deepbgc pipeline -d clusterfinder_retrained -d clusterfinder_original -d clusterfinder_geneborder -d deepbgc --output $dir/$gen_name --label clf_ret --label clf_og --label clf_gb --label deep -c product_activity -c product_class $genome
done < $input


        