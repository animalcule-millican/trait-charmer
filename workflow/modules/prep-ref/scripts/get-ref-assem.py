#!/usr/bin/env python3
import sys
import requests
import os
import pickle
import urllib.request
import time
import random
import glob
import multiprocessing 

"""
Script to fetch gene files, protein files, and genomes from NCBI refseq and genbank databases. In addition will parse assembly summary reports to gather accession and taxononmy information.
"""

def download_file(url, destination):
    """
        Download a file from a url to the specified destination.
        Will attempt to download the file up to 120 times if a too many requests error occurs. 
    """
    retry = 0
    download = False
    while download == False:
        retry += 1
        if retry < 100:
            sleepy_time = random.uniform(0.5, 2)
        elif retry > 100:
            sleepy_time = random.uniform(10, 15)
        elif retry > 120:
            return
        try:
            urllib.request.urlretrieve(url, destination)
            download = True
            return
        except urllib.error.HTTPError as e:
            if e.code == 429:  # Too Many Requests
                time.sleep(sleepy_time)  # wait a random time between 1 and 2 seconds
            else:
                print("HTTPError: ", e.code, url)
                return
        except urllib.error.ContentTooShortError as e:
                print("ContentTooShortError: ", str(e), url)
        

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
    genome_dict = {}
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
            genome_dict[accession] = {"accession": accession, "taxid": taxid, "strain": strain, "ftp": ftp, "genome": genome, "gene": gene, "protein": protein, "file_name": file_name}
    return genome_dict

def get_files(url, dirpath):
    """
    Function to download assembly related files from NCBI ftp site. 
    
    """
    genome_base = "_genomic.fna.gz"
    gene_base = "_cds_from_genomic.fna.gz"
    protein_base = "_protein.faa.gz"
    # for downloading genomes
    if genome_base in url:
        file_base = "_genomic.fna.gz"
        file_name = url.split("/")[-1].replace(genome_base, "")
        if os.path.exists(f"{dirpath}/genomes/{file_name}{file_base}"):
            print(f"Genome {file_name} downloaded")
        else:
            download_file(url, f"{dirpath}/genomes/{file_name}{file_base}")
    # for downloading gene files for predicted open reading frames
    if gene_base in url:
        file_base = "_cds_from_genomic.fna.gz"
        file_name = url.split("/")[-1].replace(gene_base, "")
        if os.path.exists(f"{dirpath}/genes/{file_name}{file_base}"):
            print(f"CDS file for genome {file_name} downloaded")
        else:
            download_file(url, f"{dirpath}/genes/{file_name}{file_base}")
    # for downloading protein files for predicted open reading frames
    if protein_base in url:
        file_base = "_protein.faa.gz"
        file_name = url.split("/")[-1].replace(protein_base, "")
        if os.path.exists(f"{dirpath}/proteins/{file_name}{file_base}"):
            print(f"Protein faa file for genome {file_name} downloaded")
        else:
            download_file(url, f"{dirpath}/proteins/{file_name}{file_base}")


def main():
    database = sys.argv[1]
    taxa = sys.argv[2]
    dirpath = sys.argv[3]
    genome_dict = get_reports(database, taxa)
    
    if sys.argv[4] is not None:
        cpu_count = int(sys.argv[4])
    elif multiprocessing.cpu_count() > 8:
        cpu_count = 8
    else:
        cpu_count = multiprocessing.cpu_count()
    
    # Download genomes in parallel
    print("Getting genome files")
    with multiprocessing.Pool(processes= cpu_count) as pool:
        genome_list = [value[3] for value in genome_dict.values()]
        args_for_get_files = [(item, dirpath) for item in genome_list]
        pool.starmap(get_files, args_for_get_files)
    print("Genome files downloaded")

    # Download genes in parallel  
    print("Getting gene files")
    with multiprocessing.Pool(processes= cpu_count) as pool:
        gene_list = [value[4] for value in genome_dict.values()]
        args_for_get_files = [(item, dirpath) for item in gene_list]
        pool.starmap(get_files, args_for_get_files)
    print("Gene files downloaded")

    # Download proteins in parallel
    print("Getting protein files")
    with multiprocessing.Pool(processes= cpu_count) as pool:
        prot_list = [value[5] for value in genome_dict.values()]
        args_for_get_files = [(item, dirpath) for item in prot_list]
        pool.starmap(get_files, args_for_get_files)
    print("Protein files downloaded")

    with open(f"{dirpath}/pkl/{taxa}-{database}_genome_info_dict.pkl", "wb") as handle:
        pickle.dump(genome_dict, handle, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == "__main__":
    main()