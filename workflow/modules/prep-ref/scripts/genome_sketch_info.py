#!/usr/bin/env python3
import os
import sys
import glob
import pandas as pd

def main():
    taxa = sys.argv[1]
    output = sys.argv[2]
    refdir = sys.argv[3]
    dirpath = f"{refdir}/genome/{taxa}"
    files = glob.glob(f"{dirpath}/*.fna.gz")
    data_dict = {}
    for file in files:
        name = os.path.basename(file).replace("_genomic.fna.gz","")
        data_dict[name] = {"name": name, 'genome_filename': file, 'protein_filename': ''}
    df = pd.DataFrame.from_dict(data_dict, orient='index')
    df.to_csv(output, sep=',', index=False)

if __name__ == "__main__":
    main()
