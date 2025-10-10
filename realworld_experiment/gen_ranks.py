import matplotlib
import matplotlib.pyplot as plt
import pandas as pd 
import numpy as np 
import glob 
import argparse
import scipy.stats as ss
import scikit_posthocs as sp

parser = argparse.ArgumentParser(
                    prog='gen_ranks',
                    description='Generate the algorithm ranks')

parser.add_argument('criteria')
parser.add_argument('agg')
parser.add_argument('--grid', nargs='?', default="")
parser.add_argument('--pct', action='store_true')

args = parser.parse_args()

# MAIN
grid = args.grid

#algs = [s.split("/")[-1] for s in glob.glob(f"results/{grid}_grid/*")] if len(grid) else ["symregg","eggp_mo",  "PySR", "Operon", "PySIPS", "gomea",  "qlattice", "gpzgd", "Random", "RF"]
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

tbl = df.groupby(["dataset","algorithm"])[criteria].apply(args.agg).unstack()
#tbl.round(2)

ranks = tbl.rank(axis=1, ascending=minobj!=args.pct, pct=args.pct)

print(ranks.mean())
print(ss.friedmanchisquare(*tbl.values.T))
df_ungrouped = tbl.reset_index().melt(id_vars='dataset', value_vars=algs, var_name='algorithm', value_name='score')
print(df_ungrouped)
test_results = sp.posthoc_conover_friedman(df_ungrouped, melted=True, block_col='dataset', group_col='algorithm', y_col='score', block_id_col='dataset')

plt.figure(figsize=(10, 2), dpi=100)
plt.title('Critical difference diagram of average score ranks')
sp.critical_difference_diagram(ranks.mean(), test_results)
plt.savefig(f'plots/ranks/diagram_{args.criteria}_{args.agg}{'_pct' if args.pct else ''}{'_'+grid if len(grid) else ''}.eps')
