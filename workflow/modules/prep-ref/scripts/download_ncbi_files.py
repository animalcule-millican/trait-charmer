#!/usr/bin/env python3
import urllib.request
import os
import sys
import pickle
import concurrent.futures
import time
import random
import glob
import urllib.error

url_dict = {}

def download_file(data_list):
    success = False
    while success is False:
        try:
            urllib.request.urlretrieve(data_list[0], data_list[1])
            time.sleep(random.uniform(0.01, 0.4))
            success = True
        except urllib.error.HTTPError as e:
            if e.code == 429:  # Too Many Requests
                print("Too many requests, sleeping for a bit...")
                time.sleep(10)
            else:
                success = True
    return True

def main():
    pickle_path = sys.argv[1]
    output_file = sys.argv[2]
    file_path = sys.argv[3]
    file_type = file_path.split("/")[-1]

    with open(pickle_path, 'rb') as f:
        gen_dict = pickle.load(f)

    for key in gen_dict.keys():
        url_dict[key] = [gen_dict[key][file_type], gen_dict[key]['ftp'].split('/')[-1]]

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        executor.map(download_file, url_dict.values())

    genome_list = glob.glob(f"{file_path}/*.gz")
    
    with open(output_file, 'w') as out:
        for genome in genome_list:
            out.write(f"{genome}\n")

if __name__ == "__main__":
    main()