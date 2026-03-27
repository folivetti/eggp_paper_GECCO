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
parser.add_argument('--pct', action='store_true')
parser.add_argument('--ext', nargs='?', default="")

args = parser.parse_args()

# MAIN
base_dir = ""

df = pd.read_csv(f"perf.csv")
# Order to display
algs = ["eggp", "eggp_fb2", "GPZGD", "Operon", "Operon_fbf", "QLattice", "PySR", "PySIPS", "SymRegg", "GPGOMEA", "neogp", "slim_gsgp", "RF"]

df = df[df.algorithm.isin(algs)]

# algs = sorted(np.unique(df.algorithm.values))
# df = df[df.algorithm.isin(algs)]

if args.criteria == "R2":
    criteria = 'r2_test'
    df.replace([np.inf, -np.inf, np.nan], 0, inplace=True)
    minobj = False
elif "P@" in args.criteria:
    k = float(args.criteria.split("@")[1])
    criteria = f'mse_test'
    df.replace([np.inf, -np.inf, np.nan], 0, inplace=True)
    minobj = True
elif 'MSE' in args.criteria:
    criteria = 'mse_test'
    df.replace([np.inf, -np.inf, np.nan], 1e10, inplace=True)
    minobj = True
else:
    criteria = 'size'
    minobj = True
    algs = [alg for alg in algs if alg not in ['random', 'RF']]
    df= df[~df.algorithm.isin(['random', 'RF'])]

tbl = df.groupby(["dataset","algorithm"])[criteria].apply(args.agg).unstack()
if "P@" in args.criteria:
    for ds in tbl.index:
        minmse = tbl.loc[ds].min()
        tbl.loc[ds] = (tbl.loc[ds] / minmse) - 1
        # convert to 0 every entry of tbl.loc[ds] < k/100 
        tbl.loc[ds] = tbl.loc[ds].clip(lower=k/100)

ranks = tbl.rank(axis=1, ascending=minobj!=args.pct, pct=args.pct)
print(ranks)
print(ranks.mean())
print(ss.friedmanchisquare(*tbl.values.T))
df_ungrouped = tbl.reset_index().melt(id_vars='dataset', value_vars=algs, var_name='algorithm', value_name='score').fillna(np.random.rand()*1e+10)
print(df_ungrouped)
test_results = sp.posthoc_conover_friedman(df_ungrouped, melted=True, block_col='dataset', group_col='algorithm', y_col='score', block_id_col='dataset')

plt.figure(figsize=(10, 2), dpi=100)
plt.title('Critical difference diagram of average score ranks')
sp.critical_difference_diagram(ranks.mean(), test_results)
plt.savefig(f'plots/ranks/diagram_{args.criteria}_{args.agg}{"_pct" if args.pct else ""}{"_" +args.ext if len(args.ext) else args.ext}.eps')
