#!/usr/bin/env python3
import sys
import requests
import os
import pickle
import urllib.request
import time
import random
import glob

def get_reports(database, taxa):
    """
    Download the assembly summary report from NCBI for a given taxa and database (refseq or genbank).
    The extract following information into a dictionary:
        - accession number.version
        - taxid
        - ftp directory path
        - create file name from ftp directory path
        - generate:
            - genome file
            - CDS from genome file
            - protein file
    Finally, return the dictionary.
    """
    url = f"https://ftp.ncbi.nlm.nih.gov/genomes/{database}/{taxa}/assembly_summary.txt"
    data_dict = {}
    response = requests.get(url)
    handle = response.text.splitlines()
    genome_base = "_genomic.fna.gz"
    gene_base = "_cds_from_genomic.fna.gz"
    protein_base = "_protein.faa.gz"
    for line in handle:
        if line.startswith("#"):
            continue
        else:
            row = line.strip().split("\t")
            accession = row[0]
            taxid = row[6]
            strain = row[8]
            ftp = row[19]
            genome = accession + genome_base
            gene = accession + gene_base
            protein = accession + protein_base
            file_name = row[19].split("/")[-1]
            data_dict[accession] = {"accession": accession, "taxid": taxid, "strain": strain, "ftp": ftp, "genome": genome, "gene": gene, "protein": protein, "file_name": file_name}
    return data_dict


def main():
    tx = sys.argv[1]
    out = sys.argv[2]
    db = sys.argv[3]

    genome_dict = get_reports(db, tx)

    with open(out, "wb") as fh:
        pickle.dump(genome_dict, fh, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == "__main__":
    main()