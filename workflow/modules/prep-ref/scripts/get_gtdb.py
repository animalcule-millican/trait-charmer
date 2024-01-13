#!/usr/bin/env python3
import sys
import requests
import os
import pickle
import urllib.request
import time
import random
import multiprocessing as mp
import subprocess

def download_file(url, destination):
    """
        Download a file from a url to the specified destination.
        Will attempt to download the file up to 120 times if a too many requests error occurs. 
    """
    print(f"Downloading {url} to {destination}")
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
        

def unpack_data(file, dirpath):
    """
    Extract files from downloaded tar.gz file and place in appropriate directory.
    """
    if "genomes" in file:
        file_name = "{dirpath}/tmp/gtdb_genomes.tar.gz"
        location = "{dirpath}/genomes"
        extract = "gtdb_genomes_reps_r214/database/*/*/*/*/*_genomic.fna.gz"
    elif "prot" in file:
        file_name = "{dirpath}/tmp/gtdb_prot.tar.gz"
        location = "{dirpath}/proteins"
        extract = "gtdb_proteins_aa_reps_r214/database/*/*/*/*/*_protein.faa.gz"
    elif "gene" in file:
        file_name = "{dirpath}/tmp/gtdb_gene.tar.gz"
        location = "{dirpath}/genes"
        extract = "gtdb_proteins_nt_reps_r214/database/*/*/*/*/*_protein.fna.gz"
    command = f"tar xzf {file_name} -C {locationo} {extract}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    return

def rename_files(dirpath):
    
    command = f""
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()

def main():
    dirpath = sys.argv[1]
    gtdb_genomes = 'https://data.gtdb.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_genomes_reps.tar.gz'
    gtdb_prot = 'https://data.gtdb.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_proteins_aa_reps.tar.gz'
    gtdb_gene = 'https://data.gtdb.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_proteins_nt_reps.tar.gz'
    atax = "https://data.gtdb.ecogenomic.org/releases/latest/ar53_metadata.tsv.gz"
    btax = "https://data.gtdb.ecogenomic.org/releases/latest/bac120_metadata.tsv.gz"

    if not os.path.exists(f"{dirpath}/tmp"):
        os.makedirs(f"{dirpath}/tmp")
    
    with mp.Pool(processes=5) as pool:
        """
        Download all gtdb files in parallel.
        """
        results = []
        results.append(pool.apply_async(download_file, args=(gtdb_genomes, f'{dirpath}/tmp/gtdb_genomes.tar.gz')))
        results.append(pool.apply_async(download_file, args=(gtdb_prot, f'{dirpath}/tmp/gtdb_prot.tar.gz')))
        results.append(pool.apply_async(download_file, args=(gtdb_gene, f'{dirpath}/tmp/gtdb_gene.tar.gz')))
        results.append(pool.apply_async(download_file, args=(atax, f'{dirpath}/tmp/archaea_taxonomy.tsv.gz')))
        results.append(pool.apply_async(download_file, args=(btax, f'{dirpath}/tmp/bacteria_taxonomy.tsv.gz')))

        for result in results:
            result.get()

    with mp.Pool(processes=3) as pool:
        """
        Extract all gtdb files in parallel.
        """
        results = []
        results.append(pool.apply_async(unpack_data, args=(f'{dirpath}/tmp/gtdb_genomes.tar.gz', dirpath)))
        results.append(pool.apply_async(unpack_data, args=(f'{dirpath}/tmp/gtdb_prot.tar.gz', dirpath)))
        results.append(pool.apply_async(unpack_data, args=(f'{dirpath}/tmp/gtdb_gene.tar.gz', dirpath)))

        for result in results:
            result.get()

if __name__ == "__main__":
    main()