import matplotlib
import matplotlib.pyplot as plt
import pandas as pd 
import numpy as np 
import glob 
import argparse

def update_elo(elo_a, elo_b, score_a, score_b, k_factor=32):
    expected_a = 1 / (1 + 10 ** ((elo_b - elo_a) / 400))
    actual_a = 1 if score_a > score_b else (0.5 if score_a == score_b else 0)
    delta = k_factor * (actual_a - expected_a)
    return elo_a + delta, elo_b - delta

parser = argparse.ArgumentParser(
                    prog='gen_elo',
                    description='Generate the algorithm ELO scores')

parser.add_argument('criteria')
parser.add_argument('agg')

args = parser.parse_args()

# MAIN
rng = np.random.default_rng()

base_dir = ""

df = pd.read_csv(f"perf.csv")
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

datasets = tbl.index.values
rng.shuffle(datasets)

elo = {a:1500 for a in algs}

for d in datasets:
    rng.shuffle(algs)
    for i, a in enumerate(algs):
        for b in algs[i+1:]:
            #print(f'Match {a} vs {b} in {d}')
            #print(tbl.loc[d, a], tbl.loc[d,b])
            if minobj:
                eloA, eloB = update_elo(elo[a], elo[b], -tbl.loc[d, a], -tbl.loc[d,b])
            else:
                eloA, eloB = update_elo(elo[a], elo[b], tbl.loc[d, a], tbl.loc[d,b])
            elo[a] = eloA
            elo[b] = eloB

df = pd.DataFrame.from_dict(elo, orient='index').rename(columns={0:'Elo'}).sort_values('Elo', ascending=False)

median_elo = df['Elo'].median()
colors = ['#2ecc71' if x >= median_elo else '#e74c3c' for x in df['Elo']]
plt.barh(range(len(df)), df['Elo'], color=colors)
plt.yticks(range(len(df)), df.index)
plt.axvline(median_elo, color='gray', linestyle='--', alpha=0.5)
plt.grid(axis='x', linestyle='--', alpha=0.3)
for spine in ['top', 'right']:
    plt.gca().spines[spine].set_visible(False)

plt.tight_layout()
plt.savefig(f'plots/ranks/elo_{args.criteria}_{args.agg}.eps')
