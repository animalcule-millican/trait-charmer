#!/bin/bash
source ~/.bashrc
find /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome -name "*.fna.gz" > /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files.txt
split -l $((($(wc -l < /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files.txt)+49)/50)) /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files.txt /home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome_files/genome_file.
