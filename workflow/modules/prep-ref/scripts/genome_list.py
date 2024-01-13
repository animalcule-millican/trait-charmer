#!/usr/bin/env python3
import os
import glob
import sys
import pandas as pd
import itertools

"""
Create a txt file list of all the genomes downloaded, this will be needed to sketch files using sourmash branchwater manysketch 
"""

def split_dict_into_parts(data_dict, num_parts):
    it = iter(data_dict.items())  # Get an iterator of the items (key-value pairs)
    size = len(data_dict)
    chunk_size = size // num_parts if num_parts else 0
    for i in range(num_parts):
        if i == num_parts - 1:  # For the last part, take all remaining items
            yield dict(itertools.islice(it, size))
        else:
            yield dict(itertools.islice(it, chunk_size))

def get_files(dirpath):
    file_names = [os.path.basename(x).split("genomic")[0] for x in glob.glob(f"{dirpath}/genome/*.fna.gz")]
    file_dict = {}
    for name in file_names:
        # 'name,genome_filename,protein_filename'
        file_dict[name] = {"name": name[:-1], 'genome_filename': f"{dirpath}/genome/{name}genomic.fna.gz",'protein_filename': ""}
    return file_dict
    

def save_list_to_file(lst, filename):
    with open(filename, 'w') as f:
        for item in lst:
            f.write("%s\n" % item)

def file_to_dict(lst, pattern):
    d = {}
    # 'name,genome_filename,protein_filename'
    for i, item in enumerate(lst):
        d[i] = {"name": os.path.basename(item).replace(pattern, ""), "genome_filename": item, "protein_filename": ''}
    return d

def main():
    dirpath = sys.argv[1]
    data_dict = get_files(dirpath)
    dicts = list(split_dict_into_parts(data_dict, 10))
    if not os.path.exists(f"{dirpath}/sketch_file"):
        os.makedirs(f"{dirpath}/sketch_file")
    for i, d in enumerate(dicts):
        df = pd.DataFrame.from_dict(d, orient='index')
        df.to_csv(f"{dirpath}/sketch_file/genome_info_{i}.csv", index=False)

if __name__ == "__main__":
    main()