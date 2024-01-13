#!/usr/bin/env python3
import pandas as pd
import sys
import pickle
import os
import urllib.request
from Bio import Entrez
import time
import random
import concurrent.futures

"""
    To help code. Get taxonomy from taxopy, and then for taxids that fail with taxopy, use Entrez to get the taxonomy.
"""

def get_tax_data(taxid, maxtry = 100):
    """once we have the taxid, we can fetch the record"""
    taxid_list = []
    retry = 0
    while retry < maxtry:
        try:
            retry += 1
            search = Entrez.efetch(id = taxid, db = "taxonomy", retmode = "xml")
            return Entrez.read(search)
        except urllib.error.HTTPError as e:
            print("HTTPError: ", e.code, taxid)
            if retry <= 60:
                stime = random.uniform(10, 15)
                print(f"Sleeping for {stime} seconds")
                time.sleep(stime)
            elif retry > 60 and retry <= maxtry:
                stime = random.uniform(25,30)
                print(f"Sleeping for {stime} seconds")
                time.sleep(stime)
                if retry == maxtry:
                    taxid_list.append(taxid)
                    with open("/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/taxid_list.txt", 'w') as f:
                        for item in taxid_list:
                            f.write("%s\n" % item)
    return
    

def parse_lineage(acc, taxid, tax_data):
    data_dict = {}
    superkingdom = ''
    phylum = ''
    class_ = ''
    order = ''
    family = ''
    genus = ''
    species = ''
    strain = ''
    if tax_data[0]['Rank'] == 'species':
        species = tax_data[0]['ScientificName']
        if len(species.split(" ")) > 2:
            strain = species
            species = species.split(" ")[0] + " " + species.split(" ")[1]
    for itm in tax_data[0]["LineageEx"]:
        if itm.get("Rank") == 'superkingdom':
            superkingdom = itm.get("ScientificName")
        elif itm.get("Rank") == 'phylum':
            phylum = itm.get("ScientificName")
        elif itm.get("Rank") == 'class':
            class_ = itm.get("ScientificName")
        elif itm.get("Rank") == 'order':
            order = itm.get("ScientificName")
        elif itm.get("Rank") == 'family':
            family = itm.get("ScientificName")
        elif itm.get("Rank") == 'genus':
            genus = itm.get("ScientificName")
    data_dict[acc] = {'ident': acc, 'taxid': taxid, 'superkingdom': superkingdom, 'phylum': phylum, 'class': class_, 'order': order, 'family': family, 'genus': genus, 'species': species, 'strain': strain}
    return data_dict

def run_get_tax(acc, taxid):
    tax_data = get_tax_data(str(taxid))
    tax_dict = parse_lineage(acc, taxid, tax_data)
    return tax_dict

def main():
    with open(sys.argv[1], 'rb') as f:
        input_dict = pickle.load(f)
    
    output_file = sys.argv[2]
    
    acc_tax = {}
    tax_dict = {}

    for value in input_dict.values():
        acc_tax[value[2]] = value[0]

    Entrez.email = sys.argv[3]
    Entrez.api_key = sys.argv[4]

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(run_get_tax, acc, taxid): (acc, taxid) for acc, taxid in acc_tax.items()}
    
    for future in as_completed(futures):
        result_dict = future.result()
        tax_dict.update(result_dict)

    df = pd.DataFrame.from_dict(tax_dict, orient='index')
    df.to_csv(output_file, sep=',', index=False)

if __name__ == "__main__":
    main()