#!/bin/bash
source ~/.bashrc 

taxa=$1
output="/home/glbrc.org/millican/projects/Inter_BRC/reference_files/assembly_reports/${taxa}_assembly_summary.pkl"
/home/glbrc.org/millican/repos/trait-charmer/workflow/modules/prep-ref/scripts/pickle_assembly_reports.py $taxa $output