#!/usr/bin/env python3
import pandas as pd
import sys
import gzip

with gzip.open(sys.argv[1], 'rt') as f:
    metadict = {}
    for line in f:
        if line.startswith("accession"):
            continue
        row = line.strip().split("\t")
        accession = row[0]
        taxid = row[73]
        if row[75] == 'none':
            strainid = ''
        elif row[75] != 'none':
            strainid = row[75]
        lineage = [tax.split("__")[-1] for tax in row[78].split(";")]
        if len(lineage) < 7:
            print(f"Lineage for {accession} is less than 7: {lineage}")
        superkingdom = lineage[0]
        phylum = lineage[1]
        clss = lineage[2]
        order = lineage[3]
        family = lineage[4]
        genus = lineage[5]
        species = lineage[6]
        if len(species) < 3:
            strain = ""
        elif len(species) >= 3:
            strain = f"{species} {strainid}"
        metadict[accession] = {'ident': accession, 'taxid': taxid, 'superkingdom': superkingdom, 'phylum': phylum, 'class': clss, 'order': order, 'family': family, 'genus': genus, 'species': species, 'strain': strain}

df = pd.DataFrame.from_dict(metadict, orient='index')
df.to_csv(sys.argv[2], sep=",", index=False)