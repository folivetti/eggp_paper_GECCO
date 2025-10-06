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

x_max = 20

def prob(n, ref, maxobj, x):
    refval = (ref - n*ref/100) if maxobj else (ref + n*ref/100)
    k = len(x[x >= refval]) if maxobj else len(x[x <= refval])
    return float(k)/len(x)

# plot the performance plot
def perfprof_plot(df, perf_measure, maxobj, ref):
    lines = ["-","--","-.",(0, (3, 5, 1, 5, 1, 5)),":"]
    linecycler = cycle(lines)

    plt.figure(figsize=(10,10))
    tab = df.pivot(index="algorithm", columns="run", values=perf_measure)
    n_problems = len(tab.columns)
    aucs = []
    algs = []
    for name, v in tab.iterrows():
        perf_x = np.arange(0, x_max, 0.1)
        perf_y = np.array([prob(x, ref, maxobj, v) for x in perf_x])

        plt.plot(perf_x, perf_y, linestyle=next(linecycler), c="k", linewidth=3.0, label=f'{name}')

    plt.axis([0, x_max, 0, 1])
    # set the x label only on the bottom figures
    if any([d == df.dataset.values[0] for d in [1028, 1089, 1193, 1199]]):
        plt.xlabel(r"$R^2$ test", fontsize=42)
    # set the y label only on the left figures
    if any([d == df.dataset.values[0] for d in [579, 192, 1028]]):
        plt.ylabel(r"$P@x$", fontsize=42)
    # keep the legend only on a single dataset
    if 1028 == df.dataset.values[0]:
        plt.legend(loc='lower right', #bbox_to_anchor=(0.5, 1.1),
                  ncol=1, fancybox=True, shadow=True, prop={'size': 28})

def perfprof_plot_mean(df, perf_measure, maxobj, ref):
    lines = ["-","--","-.",(0, (3, 5, 1, 5, 1, 5)),":"]
    linecycler = cycle(lines)

    plt.figure(figsize=(10,10))

    perf_x = np.arange(0, x_max, 0.1)
    n_problems = len(np.unique(df.dataset.values))
    for alg in np.unique(df.algorithm.values):
        perf_y = np.array([0.0 for _ in perf_x])
        df_alg = df[df.algorithm == alg]
        for d in np.unique(df.dataset.values):
            v = df_alg[df_alg.dataset == d][perf_measure].values
            tmp_y = np.array([prob(x, ref[d], maxobj, v) for x in perf_x])
            perf_y += tmp_y
        perf_y /= n_problems
        plt.plot(perf_x, perf_y, linestyle=next(linecycler), c="k", linewidth=3.0, label=f'{alg}')
    plt.axis([0, x_max, 0, 1])
    plt.xlabel(r"thr", fontsize=42)
    plt.ylabel("P@x")
    plt.legend(loc='upper left', #bbox_to_anchor=(0.5, 1.1),
                  ncol=1, fancybox=True, shadow=True, prop={'size': 28})

grid = ""
if len(sys.argv) > 1:
    if "eggp" in sys.argv[1].lower():
        grid = "eggp"
    elif "symregg" in sys.argv[1].lower():
        grid = "symregg"
    elif "pysips" in sys.argv[1].lower():
        grid = "pysips"

df = pd.read_csv(f"perf{'_'+grid if len(grid) else ''}.csv")
#df = df[df.algorithm.str.contains('|'.join(algs))]
criteria = 'r2_test' if sys.argv[1] == "R2" else 'mse_test' # MSE, R2
ref = {}
for d in np.unique(df.dataset.values):
    if criteria == 'r2_test':
        ref[d] = df[df.dataset==d][criteria].max()
        maxobj = True
    else:
        ref[d] = df[df.dataset==d][criteria].min()
        maxobj = False

# plot the performance plot for each dataset
for d in np.unique(df.dataset.values):
    df_plot = df[df.dataset==d]
    perfprof_plot(df_plot, criteria, maxobj, ref[d])
    plt.savefig(f"plots/{grid+'/' if len(grid) else ''}{sys.argv[1]}_prob_{d}.eps", bbox_inches="tight")
perfprof_plot_mean(df, criteria, maxobj, ref)
plt.savefig(f"plots/{grid+'/' if len(grid) else ''}{sys.argv[1]}_prob_mean.eps", bbox_inches="tight")
