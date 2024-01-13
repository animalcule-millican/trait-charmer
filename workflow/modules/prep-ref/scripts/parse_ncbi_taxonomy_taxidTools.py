#!/usr/bin/env python3
import pandas as pd
import sys
import pickle
import os
import concurrent.futures
import taxidTools

"""
    Parse taxonomy lineage information from NCBI taxids using taxidTools.
"""

def get_lineage(accession, taxid, tax):
        tdict = {}
        try:            
            lin = tax.getAncestry(str(taxid))
            lin.filter(['superkingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species', 'strain'])
            tdict[accession] = {"ident": accession, "taxid": taxid}
            for i in lin:
                    if i.name is None:
                            tdict[accession].update({i.rank: ""})
                    else:
                            tdict[accession].update({i.rank: i.name})
            return tdict
        except KeyError:
            print(f"KeyError: {accession} {taxid}")
            return tdict

def get_tax_obj():
    if os.path.exists("/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/pkl/ncbi_taxonomy.pkl"):
        with open("/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/pkl/ncbi_taxonomy.pkl", 'rb') as f:
            tax = pickle.load(f)
    else:
        tax = taxidTools.Taxonomy.from_taxdump("/home/glbrc.org/millican/ref_db/ncbi_taxdmp/nodes.dmp", 
            "/home/glbrc.org/millican/ref_db/ncbi_taxdmp/rankedlineage.dmp")
        with open("/home/glbrc.org/millican/repos/trait-charmer/workflow/reference/pkl/ncbi_taxonomy.pkl", 'wb') as f:
            pickle.dump(tax, f, protocol=pickle.HIGHEST_PROTOCOL)
    return tax

def main():
    with open(sys.argv[1], 'rb') as f:
        input_dict = pickle.load(f)
    
    output_file = sys.argv[2]
    
    # Load tax object from taxdump files, or build it if it doesn't exist
    tax = get_tax_obj()
    
    acc_tax = {}
    tax_dict = {}

    for value in input_dict.values():
        acc_tax[value['accession']] = value['taxid']

    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as executor:
        futures = {executor.submit(get_lineage, acc, taxid, tax): (acc, taxid) for acc, taxid in acc_tax.items()}
    
    for future in futures:
        result_dict = future.result()
        tax_dict.update(result_dict)

    df = pd.DataFrame.from_dict(tax_dict, orient='index')
    df.to_csv(output_file, sep=',', index=False)

if __name__ == "__main__":
    main()