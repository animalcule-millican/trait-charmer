#!/usr/bin/env python3
import sys
import ftplib
import os
import glob
import pickle
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from multiprocessing import cpu_count
from threading import Lock

def download_files(ftp_path, ref_path):
    """
    Download files from NCBI FTP server
    """
    ftppath = ftp_path.split(".gov/")[-1]
    file_dict = {}
    acc = ftppath.split("/")[-1]
    file_dict[acc] = {'name': acc, 'genome_filename': os.path.join(ref_path, 'genome', f"{acc}_genomic.fna.gz"), 'protein_filename': os.path.join(ref_path, 'protein', f"{acc}_protein.faa.gz")}
    success = False
    while success is False:
        try:
            with ftplib.FTP('ftp.ncbi.nlm.nih.gov') as ncbi:
                ncbi.login()
                ncbi.cwd(ftppath)
                file_list = [file for file in ncbi.nlst() if ("_genomic.fna.gz" in file) and "rna" not in file or "_cds_from_genomic.fna.gz" not in file]
                print(file_list)
                for file in file_list:
                    if "_genomic.fna.gz" in file and "_cds_from_genomic.fna.gz" not in file:
                        file_path = os.path.join(ref_path, "genome", file)
                        print(file_path)
                    file_list.append(file_path)
                    if os.path.exists(file_path):
                        continue
                    if not os.path.exists(file_path):
                        with open(file_path, 'wb') as fp:
                            ncbi.retrbinary("RETR " + file, fp.write)
                        if os.path.exists(file_path):
                            print(f"{file} downloaded") 
                success = True
        except ftplib.error_temp as e:
            print(e)
            time.sleep(20)
    return file_dict

def main():
    pickle_path = sys.argv[1]
    ref_path = sys.argv[2]
    out_pickle = sys.argv[3]

    with open(pickle_path, 'rb') as f:
        gen_dict = pickle.load(f)
    

    genome_files = {}
    with ThreadPoolExecutor(max_workers=8) as executor:
            futures = [executor.submit(download_files, value['ftp'], ref_path) for value in gen_dict.values()]
            for future in as_completed(futures):
                genome_files.update(future.result())

    with open(out_pickle, 'wb') as fh:
        pickle.dump(genome_files, fh, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == "__main__":
    main()