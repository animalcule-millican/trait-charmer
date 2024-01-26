#!/bin/bash
source ~/.bashrc
mamba activate trait-mapper
export PYTHONPATH=/home/glbrc.org/millican/mambaforge/envs/trait-mapper/lib/python3.1/site-packages:/home/glbrc.org/millican/mambaforge/envs/trait-mapper/lib/python3.11/site-packages
export MMSEQS_FORCE_MERGE=1
export pgp_dir=/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/database/pgp
export comp=$pgp_dir/Competitive_Fitness_db_h
export eco=$pgp_dir/Ecosystem_Service_db_h
export col=$pgp_dir/Plant_Colonization_db_h
export strs=$pgp_dir/Stress_Control_db_h
export output_db=$pgp_dir/pgp_trait_db_h

mmseqs createindex $pgp_dir/pgp_trait_db /home/glbrc.org/millican/TMPDIR/arbitrary-tarsier/tmp

