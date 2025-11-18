import pandas as pd
import numpy as np
import glob
import sys
from pymoo.indicators.hv import HV
import argparse
import sympy as sym

def model_size(expr):
    """Compute the size of a sympy expression."""
    if expr.is_Atom:
        return 1
    else:
        return 1 + sum(model_size(arg) for arg in expr.args)

parser = argparse.ArgumentParser(
                    prog='gen_dataframe',
                    description='Generate the results dataframe')

parser.add_argument('--thr', nargs='?', default=1.0)
parser.add_argument('--size', nargs='?', default=50)

args = parser.parse_args()

thr = float(args.thr)

# list of datasets and algorithms
datasets = ["1028_SWD", "1193_BNG_lowbwt", "192_vineyard", "522_pm10", "579_fri_c0_250_5", "650_fri_c0_500_50", "1089_USCrime", "1199_BNG_echoMonths", "210_cloud", "557_analcatdata_apnea1", "606_fri_c2_1000_10", "678_visualizing_environmental", "chemical_1_tower", "flow_stress_phip0.1", "friction_stat_one-hot", "nasa_battery_2_20min", "nikuradse_2", "chemical_2_competition",  "friction_dyn_one-hot", "nasa_battery_1_10min", "nikuradse_1"]

algs = ["SymRegg","eggp",  "PySIPS", "Operon", "QLattice", "GPGOMEA", "PySR", "neogp", "random", "GPZGD", "slim_gsgp", "RF", "random"]
ref = "eggp"
base_dir = ""

# list of things we want to keep in the CSV file
dfalgs    = []
ds        = []
r2_tests  = []
mse_tests = []
mse_trains = []
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
                if alg == "neogp":
                    dfi = pd.read_csv(f, skiprows=10, skipfooter=1, engine='python')
                elif alg == "TabPFN":
                    dfi = pd.read_csv(f, skiprows=[1])
                else:
                    dfi = pd.read_csv(f)
                msecol = 'loss' if "loss_train" in list(dfi.columns) else 'MSE'
                msecolt = 'loss' if "loss_train" in list(dfi.columns) else 'MSE'
                useval = 'train' if 'eggp' in alg or 'symregg' in alg or 'random' in alg else 'train'
                # get the two objectives from the Pareto front
                # r2s will be used to calculate the hypervolume
                r2s = dfi[['R2_train', 'max_samples']].values if alg in "RF" else dfi[[f'R2_{useval}', 'size']].values
                if alg != "slim_gsgp" and alg != "GPGOMEA" and alg != 'RF':
                    r2s[r2s[:,0] < 0, 0] = 0 # R^2 < 0 turns to 0
                    r2s[r2s[:,1] > 50, 1] = 50 # size > 50 (max) turns to 50
                r2s[:,0] = -r2s[:,0]
                # calculate the hypervolume
                hv = HV(ref_point=np.array([0.0, 50]))
                hyp = hv(r2s)


                # assign a low score for expressions larger than the maximum size
                msize = int(args.size) if alg not in ["slim_gsgp", "GPGOMEA", "GPZGD", "PySIPS", "TabPFN"] else 2000000
                if alg != "RF" and alg != "TabPFN":
                    dfi.loc[dfi['size'] > msize, "R2_train"] = 0
                    dfi.loc[dfi['size'] > msize, "R2_test"] = 0
                    dfi.loc[dfi['size'] > msize, f"{msecol}_train"] = np.inf
                    dfi.loc[dfi['size'] > msize, f"{msecol}_test"] = np.inf
                    dfi.dropna(inplace=True, how='any') # tinyGP sometimes fails

                r2max = dfi.R2_train.max()
                ix = dfi.OOB_score.idxmin() if alg == "RF" else dfi[dfi.R2_train >= thr*r2max]['size'].idxmin()

                v = dfi.loc[ix, 'R2_test']
                vs = 10000 if alg == "RF" else dfi.loc[ix, 'size']

                msemin = dfi[f"{msecol}_{useval}"].min()
                mse_trains.append(msemin)
                if alg == "neogp":
                    ixmse = 199
                elif alg == "RF":
                    imxse = ix
                else:
                    ixmse = dfi[dfi[f"{msecol}_{useval}"] <= (2 - thr)*msemin]['size'].idxmin()

                vmse = dfi.loc[ixmse, f"{msecolt}_test"]
                vsmse = 100000 if alg == "RF" else dfi.loc[ixmse, 'size']


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
df = pd.DataFrame({"run":runs, "algorithm": dfalgs, "dataset": ds, "r2_test": r2_tests, "mse_train" : mse_trains, "mse_test": mse_tests, "hypervolume": hyps, 'size':sizes, 'size_mse':sizesmse})
outname = "perf.csv"
df.to_csv(outname, index=False)
