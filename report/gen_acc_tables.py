from collections import Counter
from itertools import cycle
from sklearn.metrics import auc
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd 
import numpy as np 
import glob 
from pymoo.indicators.hv import HV
from scipy.stats import wilcoxon 
from functools import partial
import sys

# interquantile range
def iqr(x):
    return np.subtract(*np.percentile(x, [75, 25]))

# AUC of the performance plot
def auc_agg(x):
    n_problems = 30
    x = x[x>=0].sort_values()
    n_gt0 = x.shape[0]
    perf_x = [0]
    perf_y = [n_gt0/n_problems]
    for k, v1 in Counter(x).items():
        if k == 0:
            n_gt0 = n_gt0 - v1
            continue
        perf_x.append(k)
        perf_y.append(n_gt0/n_problems)
        n_gt0 = n_gt0 - v1
    return auc(perf_x, perf_y)

def prob(n, ref, maxobj, x):
    d = x.name[0]

    refval = (ref[d] - n*ref[d]/100) if maxobj else (ref[d] + n*ref[d]/100)
    x = x.values

    k = len(x[x >= refval]) if maxobj else len(x[x <= refval])
    return float(k)/len(x)

# MAIN
algref = "eggp"
base_dir = ""

df = pd.read_csv(f"perf.csv")

# Order to display
algs = ["eggp", "GPZGD", "Operon", "QLattice", "PySR", "PySIPS", "SymRegg", "GPGOMEA", "neogp", "slim_gsgp", "RF"]

df = df[df.algorithm.isin(algs)]

criteria = 'r2_test' if sys.argv[1] == "R2" else 'mse_test' # MSE, R2

if sys.argv[1] == "R2":
    df.replace([np.inf, -np.inf, np.nan], 0, inplace=True)
else:
    df.replace([np.inf, -np.inf, np.nan], 1e10, inplace=True)

maxobj = sys.argv[1] == "R2"
if sys.argv[2] == 'mean':
    aggreg = 'mean'
    aggalt = ['mean', 'std']
elif sys.argv[2] == 'median':
    aggreg = 'median'
    aggalt = ['median', iqr]
elif sys.argv[2] == 'auc':
    aggreg = auc_agg
elif sys.argv[2] == 'min':
    aggreg = 'min'
else:
    n = float(sys.argv[2].split("@")[1])
    ref = {}
    for d in np.unique(df.dataset.values):
        if criteria == 'r2_test':
            ref[d] = df[df.dataset==d][criteria].max()
        else:
            ref[d] = df[df.dataset==d][criteria].min()

    pfun = partial(prob, n, ref, maxobj)
    aggreg = pfun

    
if isinstance(aggreg, list):
    tbl = df.groupby(["dataset","algorithm"])[criteria].agg(aggreg).unstack()
else:
    tbl = df.groupby(["dataset","algorithm"])[criteria].apply(aggreg).unstack()
#tbl.round(2)


if sys.argv[2] == 'auc' or sys.argv[2][0] == 'P' or sys.argv[2] == 'min':
    tbl.loc["mean"] = tbl.mean()
    s = tbl[algs].style.highlight_max(axis=1, props="mathbf:--rwrap").format("{:.2f}")
    print(s.to_latex())
else:
    tblalt = df.groupby(["dataset","algorithm"])[criteria].agg(aggalt)
    tblalt.round(2)
    if sys.argv[2] in ['mean', 'median']:
        if sys.argv[2] == 'mean':
            mean_col, std_col = 'mean', 'std'
        else:
            mean_col, std_col = 'median', 'iqr'
        tblalt = tblalt.apply(lambda x: f"{x[mean_col]:.2e} \\pm {x[std_col]:.2f}", axis=1)
    tblalt = tblalt.unstack()
    print(tblalt[algs].to_latex())

print("=====Wilcoxon test for the rank using the alternative of eggp_mo being better or worse than the other=====")
for alg in algs:
    print(alg, wilcoxon(tbl[algref], tbl[alg], alternative="greater" if maxobj else "less", method="exact").pvalue)
print()

print("\n====Size====")
tbl_sz = df.groupby(["dataset","algorithm"])['size'].mean().unstack()
tbl_sz.loc["mean"] = tbl_sz.mean()
# replace "_" with "\_" in the dataset and algorithm names for LaTeX compatibility
algs_sz = [alg for alg in algs if alg not in ['RF', 'random']]
tbl_sz.index = tbl_sz.index.str.replace("_", "\\_")
s = tbl_sz[algs_sz].style.highlight_min(axis=1, props="mathbf:--rwrap")
s.format("{:.0f}")
print(s.to_latex())

ranks = tbl.rank(axis=1)

ranks.loc["mean"] = ranks.mean()
print("\n====Ranks====")
s = ranks[algs].style.highlight_min(axis=1, props="mathbf:--rwrap")
s.format("{:.2f}")
print(s.to_latex())
