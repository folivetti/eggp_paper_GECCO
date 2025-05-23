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
    if any([d in df.dataset.values for d in ["nasa", "niku"]]):
        plt.xlabel(r"$R^2$ test", fontsize=42)
    if any([d in df.dataset.values for d in ["chemical_1", "nasa_battery_1_10min"]]):
        plt.ylabel(r"$P[alg\_perf \geq x]$", fontsize=42)

    if "chemical_1" in df.dataset.values:
        plt.legend(loc='lower left', #bbox_to_anchor=(0.5, 1.1),
                  ncol=1, fancybox=True, shadow=True, prop={'size': 28})
    df_auc = pd.DataFrame({"algorithm": algs, "AUC": aucs})

# list of datasets and algorithms
largesize = 30
smallsize = 20
datasets = ["chemical_1_tower", "chemical_2_competition", "flow_stress_phip0.1", "friction_dyn_one-hot", "friction_stat_one-hot", "nasa_battery_1_10min", "nasa_battery_2_20min", "nikuradse_1", "nikuradse_2"]
maxsize = {"chemical_1_tower" : largesize, "chemical_2_competition" : largesize, "flow_stress_phip0.1" : smallsize, "friction_dyn_one-hot" : largesize, "friction_stat_one-hot" : largesize, "nasa_battery_1_10min" : smallsize, "nasa_battery_2_20min" : smallsize, "nikuradse_1" : smallsize, "nikuradse_2" : smallsize}
alias = {"chemical_1_tower" : "chemical 1", "chemical_2_competition" : "chemical 2", "flow_stress_phip0.1" : "flow", "friction_dyn_one-hot" : "friction dyn", "friction_stat_one-hot" : "friction", "nasa_battery_1_10min" : "nasa 1", "nasa_battery_2_20min" : "nasa 2", "nikuradse_1" : "niku 1", "nikuradse_2" : "niku 2"}
algs = ["eggp_mo", "eggp_so", "PySR", "Operon", "tinyGP"]

# list of things we want to keep in the CSV file
dfalgs    = []
ds        = []
r2_tests  = []
r2_ideals = []
runs      = []
hyps      = []
sizes     = []

# for each dataset ...
for d in datasets:
    # ...and each algorithm...
    for alg in algs:
        # ... and each run
        for i,f in enumerate(glob.glob(f"results/{alg}/{d}/*.csv")):
            try:
                dfi = pd.read_csv(f)
                
                # get the two objectives from the Pareto front
                # r2s will be used to calculate the hypervolume
                r2s = dfi[['R2_train', 'size']].values
                r2s[r2s[:,0] < 0, 0] = 0 # R^2 < 0 turns to 0
                r2s[r2s[:,1] > maxsize[d], 1] = maxsize[d] # size > 50 (max) turns to 50
                r2s[:,0] = -r2s[:,0]
                # calculate the hypervolume
                hv = HV(ref_point=np.array([0.0, maxsize[d]]))
                hyp = hv(r2s)

                # if the algorithm is Operon
                if alg == "Operon":
                    # assign a low score for expressions larger than the maximum size
                    dfi.loc[dfi['size'] > maxsize[d], "R2_train"] = 0
                    dfi.loc[dfi['size'] > maxsize[d], "R2_test"] = 0
                dfi.dropna(inplace=True, how='any') # for tinyGP
                ix = dfi.R2_train.argmax() 
                v = dfi.loc[ix, 'R2_test']
                vs = dfi.loc[ix, 'size']

                # append all the values
                dfalgs.append(alg)
                ds.append(alias[d])
                r2_tests.append(v)
                r2_ideals.append(dfi.R2_test.max())
                runs.append(i)
                hyps.append(hyp)
                sizes.append(vs)
            except:
                pass

# create the dataframe and save it
df = pd.DataFrame({"run":runs, "algorithm": dfalgs, "dataset": ds, "r2_test": r2_tests, "r2_ideal": r2_ideals, "hypervolume": hyps, 'size':sizes})
df.to_csv("r2_perf.csv", index=False)

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

# plot the performance plot for each dataset
for d in datasets:
    df_plot = df[df.dataset==alias[d]]
    perfprof_plot(df_plot, "r2_test")
    plt.savefig(f"plots/r2_perf_{d}.eps", bbox_inches="tight")

# replace any infinite or nan with 0 (only happens with tinyGP)
df.replace([np.inf, -np.inf, np.nan], 0, inplace=True)
# create a stats table for R^2 test, when selecting the best R^2 training and R^2 ideal, when selecting the best R^2 test
tbl = df.groupby(["dataset","algorithm"])[['r2_test', 'r2_ideal']].agg(['mean','std', 'median',iqr, auc_agg])
print("=====STATS====")
print(tbl)

tbl_r2 = df.groupby(["dataset","algorithm"])['r2_test'].agg('median').unstack()
print("=====Wilcoxon test for the rank using the alternative of eggp_mo being better than the other=====")
for alg in ["eggp_so", "Operon", "PySR", "tinyGP"]:
    print(alg, wilcoxon(tbl_r2["eggp_mo"], tbl_r2[alg], alternative="greater", method="exact").pvalue, wilcoxon(tbl_r2["eggp_mo"], tbl_r2[alg], alternative="less", method="exact").pvalue)
print()

tbl_auc = df.groupby(["dataset","algorithm"])['r2_test'].agg(auc_agg).unstack()
print("=====Wilcoxon test for the AUC using the alternative of eggp_mo being better than the other=====")
for alg in ["eggp_so", "Operon", "PySR", "tinyGP"]:
    print(alg, wilcoxon(tbl_auc["eggp_mo"], tbl_auc[alg], alternative="greater", method="exact").pvalue, wilcoxon(tbl_auc["eggp_mo"], tbl_auc[alg], alternative="less", method="exact").pvalue)

tbl_auc.loc["mean"] = tbl_auc.mean()
print("\n====AUC====")
s = tbl_auc[["eggp_mo", "eggp_so", "Operon", "PySR", "tinyGP"]].style.highlight_max(axis=1, props="mathbf:--rwrap")
s.format("{:.2f}")
print(s.to_latex())

print("\n====Size====")
tbl_sz = df.groupby(["dataset","algorithm"])['size'].mean().unstack()
tbl_sz.loc["mean"] = tbl_sz.mean()
s = tbl_sz[["eggp_mo", "eggp_so", "Operon", "PySR", "tinyGP"]].style.highlight_min(axis=1, props="mathbf:--rwrap")
s.format("{:.2f}")
print(s.to_latex())

# calculate the rank of each algorithm by dataset based on the mean r2_test 
ranks = tbl["r2_test"]["median"].unstack().rank(axis=1, ascending=False)
ranks.loc["mean"] = ranks.mean()
print("\n====Ranks====")
s = ranks[["eggp_mo", "eggp_so", "Operon", "PySR", "tinyGP"]].style.highlight_min(axis=1, props="mathbf:--rwrap")
s.format("{:.2f}")
print(s.to_latex())

print("\n====hypervolume====")
tbl = df.pivot_table(index="dataset", columns="algorithm", values="hypervolume", aggfunc=['mean','std'])
# merge the levels mean and std into a single level
tbl.columns = ['_'.join(col).strip() for col in tbl.columns.values]
for alg in algs:
    tbl[f"{alg}"] = tbl[[f"mean_{alg}", f"std_{alg}"]].apply(lambda x: f"${x.iloc[0]:.2f} \\pm {x.iloc[1]:.2f}$", axis=1)

# rename indeces by taking the first element after splitting on _ 
#tbl.index = tbl.index.str.split("_").str[0]
s = tbl[["eggp_mo", "eggp_so", "Operon", "PySR"]].style.highlight_max(axis=1, props="mathbf:--rwrap")
print(s.to_latex())
