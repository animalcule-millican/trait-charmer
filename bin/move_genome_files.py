#!/usr/bin/env python3
import os
import glob
import sys
import pickle
import pandas as pd
import concurrent.futures


def make_pickle_list(input_file): 
    with open(input_file, 'rb') as f:
        pdict = pickle.load(f)
        for key in pdict:
            yield key

def make_csv_list(input_file):
    with open(input_file, 'r') as f:
        for line in f:
            yield line.strip().split(',')[0]

def create_file_list(input_list, taxa):
    dirlist = ["/home/glbrc.org/millican/ref_db/sourDB/genomes", f"/home/glbrc.org/millican/ref_db/sourDB/genomes/{taxa}", f"/home/glbrc.org/millican/ref_db/reference_genomes/genomes/{taxa}", "/home/glbrc.org/millican/ref_db/reference_genomes/genomes", f"/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome", "/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome", f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome/{taxa}", f"/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome/{taxa}"]
    #if taxa == "bacteria":
    #    dirlist = ["/home/glbrc.org/millican/ref_db/sourDB/genomes", f"/home/glbrc.org/millican/ref_db/sourDB/genomes/{taxa}", f"/home/glbrc.org/millican/ref_db/reference_genomes/genomes/{taxa}", "/home/glbrc.org/millican/ref_db/reference_genomes/genomes", f"/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome", "/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome"]
    #elif taxa == "archaea":
    #    dirlist = ["/home/glbrc.org/millican/ref_db/sourDB/genomes", f"/home/glbrc.org/millican/ref_db/sourDB/genomes/{taxa}", f"/home/glbrc.org/millican/ref_db/reference_genomes/genomes/{taxa}", "/home/glbrc.org/millican/ref_db/reference_genomes/genomes", f"/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/genome", "/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome"]
    #elif taxa != "bacteria" and taxa != "archaea": 
    file_list = []
    f1 = f2 = f3 = None
    for item in input_list:
        for dirpath in dirlist:
            try:
                file_list.append(glob.glob(os.path.join(dirpath, item + '*fna.gz'))[0])
            except IndexError:
                print(f"Index error for {os.path.join(dirpath, item + '*fna.gz')}")
        #try:
        ##    f2 = glob.glob(os.path.join(dirlist[1], item + '*fna.gz'))[0]
        #except IndexError:
        #    print(f"Index error for {os.path.join(dirlist[1], item + '*fna.gz')}")
        #try:
        #    f3 = glob.glob(os.path.join(dirlist[2], item + '*fna.gz'))[0]
        #except IndexError:
        #    print(f"Index error for {os.path.join(dirlist[2], item + '*fna.gz')}")
        #try:
        #    f4 = glob.glob(os.path.join(dirlist[2], item + '*fna.gz'))[0]
        #except IndexError:
        #    print(f"Index error for {os.path.join(dirlist[2], item + '*fna.gz')}")
        #if f1 is not None:
        #    file_list.append(f1)
        #if f2 is not None:
        #    file_list.append(f2)
        #if f3 is not None:
        #    file_list.append(f3)
        #else:
        #    print(f"Could not find {item}")
    return file_list        

def move_files(file, taxa):
    os.system(f"mv {file} /home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_genomes/{taxa}")

def correct_file_names(taxa):
    file_list = glob.glob(f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_genomes/{taxa}/*fna.gz")
    for file in file_list:
        if file.endswith(".genomic.fna.gz"):
            new_name = file.replace(".genomic.fna.gz", "_genomic.fna.gz")
            os.system(f"mv {file} {new_name}")

def main():
    input_file = f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/assembly_reports/{sys.argv[1]}_assembly_summary.pkl"
    taxa = sys.argv[1]

    if not os.path.exists(f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome/{taxa}"):
        os.makedirs(f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/genome/{taxa}")
    
    input_list = make_pickle_list(input_file)
    
    file_list = create_file_list(input_list, taxa)
    
    print(file_list)
    
    with concurrent.futures.ProcessPoolExecutor(max_workers = 12) as executor:
        executor.map(lambda file: move_files(file, taxa), file_list)
    
    correct_file_names(taxa)

    genome_dict = {}
    genome_list = glob.glob(f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_genomes/{taxa}/*fna.gz")
    for file in genome_list:
        filename = os.path.basename(file).replace("_genomic.fna.gz", "")
        genome_dict[filename] = {"name": filename, "genome_filename": file, "protein_filename": ""}
    
    df = pd.DataFrame.from_dict(genome_dict, orient = "index")
    df.to_csv(f"/home/glbrc.org/millican/projects/Inter_BRC/reference_files/reference_genomes/{taxa}_genome_files.csv", index = False)    

if __name__ == "__main__":
    main()
