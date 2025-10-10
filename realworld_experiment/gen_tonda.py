import matplotlib
import matplotlib.pyplot as plt
import pandas as pd 
import numpy as np 
import glob 
import argparse
from collections import Counter

parser = argparse.ArgumentParser(
                    prog='gen_tonda',
                    description='Generate the Tonda\'s table')

parser.add_argument('criteria')
parser.add_argument('--grid', nargs='?', default="")

args = parser.parse_args()

# MAIN
grid = args.grid
rng = np.random.default_rng()

#algs = [s.split("/")[-1] for s in glob.glob(f"results/{grid}_grid/*")] if len(grid) else ["symregg","eggp_mo",  "PySR", "Operon", "PySIPS", "gomea",  "qlattice", "gpzgd","Random"]
base_dir = f"{grid}_grid/" if len(grid) else ""

df = pd.read_csv(f"perf{'_'+grid if len(grid) else ''}.csv")
algs = sorted(np.unique(df.algorithm.values))
df = df[df.algorithm.isin(algs)]

if args.criteria == "R2":
    criteria = 'r2_test'
    df.replace([np.inf, -np.inf, np.nan], 0, inplace=True)
    minobj = False
else:
    criteria = 'mse_test'
    df.replace([np.inf, -np.inf, np.nan], 1e10, inplace=True)
    minobj = True


medals = {a:Counter() for a in algs}

for d in np.unique(df.dataset):
    scores = {k:sorted(np.array(list(v.values())) if minobj else -np.array(list(v.values()))) for k,v in df[(df.dataset==d)].pivot_table(criteria,'run','algorithm').to_dict().items()}
    df_rank = pd.DataFrame.from_dict(scores).rank(axis=1)
    for a in algs:
        c = Counter([str(len(algs))+'p' if np.isnan(x) else str(int(x))+'p' for x in df_rank[a].values])
        medals[a] |= c
medals_df = pd.DataFrame.from_dict(medals, orient='index')
cols = sorted(medals_df.columns)
print(medals_df.sort_values(by=cols, axis=0))
