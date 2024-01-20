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

def main():
    pickle_path = sys.argv[1]
    ref_path = sys.argv[2]
    out_pickle = sys.argv[3]
    
    with open(pickle_path, 'rb') as f:
        gen_dict = pickle.load(f)
    
    genome_files = {}
    
    for value in gen_dict.values():
        ftppath = value["ftp"].split(".gov/")[-1]
        acc = ftppath.split("/")[-1]
        genome_files[acc] = {'name': acc, 'genome_filename': os.path.join(ref_path, 'genome', f"{acc}_genomic.fna.gz"), 'protein_filename': ""}
        print(acc)

    with open(out_pickle, 'wb') as fh:
        pickle.dump(genome_files, fh, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == "__main__":
    main()