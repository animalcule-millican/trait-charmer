#!/bin/bash

# Name of the tarball
tarball="/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files_tar/reference_genome_files_${1}.tar"

# Text file containing the list of files
file_list="/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files/genome_file.${1}"

# Create the tarball
while IFS= read -r file
do
  tar -rf "$tarball" "$file"
done < "$file_list"

# Compress the tarball
gzip -f "$tarball"