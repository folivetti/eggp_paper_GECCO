from collections import Counter
from itertools import cycle
from sklearn.metrics import auc
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import glob
import sys

# Setup Matplotlib style
plt.style.use('seaborn-v0_8-colorblind')
font = {'family' : 'sans-serif',
        'weight' : 'normal',
        'size'   : 28}

matplotlib.rc('font', **font)
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

# plot the performance plot
def perfprof_plot(df, perf_measure):
    lines = ["-","--","-.",(0, (3, 5, 1, 5, 1, 5)),":"]
    linecycler = cycle(lines)

    plt.figure(figsize=(10,10))
    tab = df.pivot(index="algorithm", columns="run", values=perf_measure)
    n_problems = len(tab.columns)
    aucs = []
    algs = []
    for name, v in tab.iterrows():
        v = v[v>=0].sort_values()
        n_gt0 = v.shape[0]
        perf_x = [0]
        perf_y = [n_gt0/n_problems]
        for k, v1 in Counter(v).items():
            if k == 0:
                n_gt0 = n_gt0 - v1
                continue
            perf_x.append(k)
            perf_y.append(n_gt0/n_problems)
            n_gt0 = n_gt0 - v1

        plt.plot(perf_x, perf_y, linestyle=next(linecycler), c="k", linewidth=3.0, label=f'{name}')

        aucs.append(auc(perf_x, perf_y))
        algs.append(name)

    plt.axis([0, 1, 0, 1])
    # set the x label only on the bottom figures
    if any([d == df.dataset.values[0] for d in [1028, 1089, 1193, 1199]]):
        plt.xlabel(r"$R^2$ test", fontsize=42)
    # set the y label only on the left figures
    if any([d == df.dataset.values[0] for d in [579, 192, 1028]]):
        plt.ylabel(r"$P[alg\_perf \geq x]$", fontsize=42)
    # keep the legend only on a single dataset
    if 1028 == df.dataset.values[0]:
        plt.legend(loc='lower right', #bbox_to_anchor=(0.5, 1.1),
                  ncol=1, fancybox=True, shadow=True, prop={'size': 28})

grid = ""
if len(sys.argv) > 1:
    if "eggp" in sys.argv[1].lower():
        grid = "eggp"
    elif "symregg" in sys.argv[1].lower():
        grid = "symregg"
    elif "pysips" in sys.argv[1].lower():
        grid = "pysips"


df = pd.read_csv(f"perf{'_' + grid if len(grid) > 0 else ''}.csv")


# plot the performance plot for each dataset
for d in np.unique(df.dataset.values):
    df_plot = df[df.dataset==d]
    perfprof_plot(df_plot, "r2_test")
    plt.savefig(f"plots/{grid+'/' if len(grid) else ''}r2_perf_{d}.eps", bbox_inches="tight")
