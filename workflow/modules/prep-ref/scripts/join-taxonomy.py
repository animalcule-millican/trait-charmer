#!/usr/bin/env python3
import os
import sys
import pandas as pd

def main():
    # list of file names to read
    dirpath = sys.argv[1]
    files = sys.argv[2:]

    # read them into pandas dataframes and concatenate them
    df_list = [pd.read_csv(file, dtype=str) for file in files]
    final_df = pd.concat(df_list, ignore_index=True)

    # save the final dataframe to a new csv file
    final_df.to_csv(f'{dirpath}/taxonomy/reference_taxonomy.csv', index=False)

if __name__ == "__main__":
    main()