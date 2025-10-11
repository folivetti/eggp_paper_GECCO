import pandas as pd
import numpy as np
import glob
import sys
from pymoo.indicators.hv import HV
import argparse

parser = argparse.ArgumentParser(
                    prog='gen_dataframe',
                    description='Generate the results dataframe')

parser.add_argument('--grid', nargs='?', default="")
parser.add_argument('--thr', nargs='?', default=1.0)

args = parser.parse_args()

#grid = ""
#if len(sys.argv) > 1:
#    if "eggp" in sys.argv[1].lower():
#        grid = "eggp"
#    elif "symregg" in sys.argv[1].lower():
#        grid = "symregg"
#    elif "pysips" in sys.argv[1].lower():
#        grid = "pysips"

grid = args.grid
thr = float(args.thr)

# list of datasets and algorithms
datasets = ["chemical_1_tower", "flow_stress_phip0.1", "friction_stat_one-hot", "nasa_battery_2_20min", "nikuradse_2", "chemical_2_competition",  "riction_dyn_one-hot", "nasa_battery_1_10min", "nikuradse_1"]


if grid == "eggp":
    algs = ["eggp_mo_evenmorecx",    "eggp_mo_half",   "eggp_mo_i50",
            "eggp_mo_morecx",   "eggp_mo_moremut",  "eggp_mo_onlycx",
            "eggp_mo_ts2", "eggp_mo_evenmorecx_2",  "eggp_mo_i10r5",
            "eggp_mo_k3",   "eggp_mo_moregen",  "eggp_mo_morepop",
            "eggp_mo_onlymut",  "eggp_mo_ts5"]
    ref = "eggp_mo_i50"
    base_dir = "eggp_grid/"
elif grid == "symregg":
    algs = ["symregg", "symregg_cx", "symregg_old", "symregg_onlycx", "symregg_zip115"]
    ref  = "symregg_cx"
    base_dir = "symregg_grid/"
elif grid == "pysips":
    algs = ["PySIPS",  "PySIPS_1000_50",  "PySIPS_500_10_best",  "PySIPS_500_50_best",  "PySIPS_unlimited"]
    ref = "PySIPS"
    base_dir = "PySIPS_grid/"
else:
    algs = ["symregg","eggp_mo",  "PySIPS", "random", "operon", "qlattice", "gomea"] # "qlattice", "gpzgd", "Random", "RF"]
    ref = "eggp_mo"
    base_dir = ""

# list of things we want to keep in the CSV file
dfalgs    = []
ds        = []
r2_tests  = []
mse_tests = []
runs      = []
hyps      = []
sizes     = []
sizesmse  = []


# for each dataset ...
for d in datasets:
    # ...and each algorithm...
    for alg in algs:
        # ... and each run
        directory = f"results/{base_dir}{alg}/{d}/*.csv"

        for i,f in enumerate(glob.glob(directory)):
            try:
                dfi = pd.read_csv(f)
                msecol = 'loss' if "loss_train" in list(dfi.columns) else 'MSE'
                useval = 'train' if 'eggp' in alg or 'symregg' in alg else 'train'

                # get the two objectives from the Pareto front
                # r2s will be used to calculate the hypervolume
                r2s = dfi[[f'R2_{useval}', 'size']].values
                r2s[r2s[:,0] < 0, 0] = 0 # R^2 < 0 turns to 0
                r2s[r2s[:,1] > 50, 1] = 50 # size > 50 (max) turns to 50
                r2s[:,0] = -r2s[:,0]
                # calculate the hypervolume
                hv = HV(ref_point=np.array([0.0, 50]))
                hyp = hv(r2s)

                # if the algorithm is Operon
                if alg == "Operon":
                    # assign a low score for expressions larger than the maximum size
                    dfi.loc[dfi['size'] > 50, "R2_train"] = 0
                    dfi.loc[dfi['size'] > 50, "R2_test"] = 0
                    dfi.loc[dfi['size'] > 50, f"{msecol}_train"] = np.inf
                    dfi.loc[dfi['size'] > 50, f"{msecol}_test"] = np.inf
                dfi.dropna(inplace=True, how='any') # tinyGP sometimes fails

                r2max = dfi.R2_train.max()
                ix = dfi[dfi.R2_train >= thr*r2max]['size'].idxmin()

                # ix = dfi.R2_train.idxmax()
                # ix = dfi.R2_test.idxmax()
                v = dfi.loc[ix, 'R2_test']
                vs = dfi.loc[ix, 'size']

                msemin = dfi[f"{msecol}_{useval}"].min()
                ixmse = dfi[dfi[f"{msecol}_{useval}"] <= (2 - thr)*msemin]['size'].idxmin()
                # ixmse = dfi[f"{msecol}_{useval}"].idxmin()
                # ixmse = dfi[f"{msecol}_test"].idxmin()
                vmse = dfi.loc[ixmse, f"{msecol}_test"]
                #vmse = np.round(np.log2(dfi.loc[ixmse, f"{msecol}_test"]))
                vsmse = dfi.loc[ixmse, 'size']


                # append all the values
                dfalgs.append(alg)
                ds.append(d)
                r2_tests.append(v)
                mse_tests.append(vmse)
                runs.append(i)
                hyps.append(hyp)
                sizes.append(vs)
                sizesmse.append(vsmse)

                if np.isinf(v):
                    print(f"INF IN {f}")
            except Exception as e:
                print(f"ERROR IN {f} - {e}")

# create the dataframe and save it
df = pd.DataFrame({"run":runs, "algorithm": dfalgs, "dataset": ds, "r2_test": r2_tests, "mse_test": mse_tests, "hypervolume": hyps, 'size':sizes, 'size_mse':sizesmse})
outname = f"perf_{grid}.csv" if grid!="" else "perf.csv"
df.to_csv(outname, index=False)
