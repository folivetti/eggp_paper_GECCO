import pandas as pd
import numpy as np
import glob
import sys
import argparse
import random 

parser = argparse.ArgumentParser(
                    prog='gen_dominance',
                    description='Generate the results of dominance to pysips')

parser.add_argument('--n', nargs='?', default=1000)

args = parser.parse_args()

def get_best(df, useloss=False, maxSize=50):
    col = 'loss_train' if useloss else 'MSE_train' 
    col_test = 'loss_test' if useloss else 'MSE_test'
    df_sel = df[df['size'] <= maxSize]
    if df_sel.empty:
        return np.inf, np.inf, np.inf
    ixmse = df[df['size'] <= maxSize][col].idxmin()
    vmse_tr = df.loc[ixmse, col]
    vmse_te = df.loc[ixmse, col_test]
    vsmse = df.loc[ixmse, 'size']
    return vmse_tr, vmse_te, vsmse 

# list of datasets and algorithms
datasets = ["1028_SWD", "1193_BNG_lowbwt", "192_vineyard", "522_pm10", "579_fri_c0_250_5", "650_fri_c0_500_50", "1089_USCrime", "1199_BNG_echoMonths", "210_cloud", "557_analcatdata_apnea1", "606_fri_c2_1000_10", "678_visualizing_environmental", "chemical_1_tower", "flow_stress_phip0.1", "friction_stat_one-hot", "nasa_battery_2_20min", "nikuradse_2", "chemical_2_competition",  "friction_dyn_one-hot", "nasa_battery_1_10min", "nikuradse_1"]


algs = ["SymRegg","eggp", "Operon", "PySR", "random"]
ref = "PySIPS"
N = int(args.n)

# list of things we want to keep in the CSV file
ds = []
alg_dom_rates = {}
alg_best_rates = {}

# for each dataset ...
for d in datasets:
    directory_ref = f"results/{ref}/{d}/*.csv"
    directories_algs = {alg: f"results/{alg}/{d}/*.csv" for alg in algs}

    for k in range(N):
        if k % 100 == 0:
            print(f"Processing dataset {d}, run {k}/{N}")
        # ... get the reference performance first
        ds.append(d)
        f_ref = random.choice(glob.glob(directory_ref))
        #print(f"{f_ref}")
        vmse_tr_ref, vmse_te_ref, vsmse_ref = get_best(pd.read_csv(f_ref), useloss=False, maxSize=50)
        dom = 1
        best = 1

        # ... then each algorithm
        for alg in algs:
            f = random.choice(glob.glob(directories_algs[alg]))
            useloss = alg == 'SymRegg' or alg == 'eggp' or alg == 'random'
            vmse_tr_alg, vmse_te_alg, vsmse_alg = get_best(pd.read_csv(f), useloss=useloss, maxSize=vsmse_ref)

            # compare with the reference
            dom_rate = int(((vmse_tr_alg <= vmse_te_ref) and (vsmse_alg < vsmse_ref)) or ((vmse_tr_alg < vmse_te_ref) and (vsmse_alg <= vsmse_ref)))
            best_rate = int((vmse_te_alg <= vmse_te_ref) and dom_rate)

            alg_dom_rates.setdefault(alg, []).append(dom_rate)
            alg_best_rates.setdefault(alg, []).append(best_rate)
            dom = 0 if dom_rate == 1 else dom 
            best = 0 if best_rate == 1 else best 

            #print(f"{f}")
        alg_dom_rates.setdefault("PySIPS", []).append(dom)
        alg_best_rates.setdefault("PySIPS", []).append(best)
df_domrates = pd.DataFrame({"dataset": ds} | alg_dom_rates)
df_bestrates = pd.DataFrame({"dataset": ds} | alg_best_rates)

df_domrates.to_csv("dominance_rates.csv", index=False)
df_bestrates.to_csv("best_rates.csv", index=False)
