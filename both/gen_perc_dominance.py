import pandas as pd 
import numpy as np 

algs = ["eggp", "Operon", "PySR", "SymRegg"]
# Let's get the dominance rates for each algorithm 
df = pd.read_csv("dominance_rates.csv")
df.drop(columns=['PySIPS','random'], inplace=True)  # remove PySIPS column
# the first column of this dataframe is the dataset name and the other columns are the algorithm 
# let's average the dominance rates for each algorithm at each dataset and display the total average as well 

avg_dom = df.groupby('dataset').mean()
avg_dom = avg_dom[algs]
avg_dom.loc['total'] = df[df.columns[1:]].mean(axis=0)
avg_dom *= 100
# format to latex and in percent with two decimal places
print(avg_dom.to_latex(float_format="%.0f"))


df = pd.read_csv("best_rates.csv")
df.drop(columns=['PySIPS','random'], inplace=True)  # remove PySIPS column
avg_dom2 = df.groupby('dataset').mean()
avg_dom2 = avg_dom2[algs]
avg_dom2.loc['total'] = df[df.columns[1:]].mean(axis=0)
avg_dom2 *= 100
print(avg_dom2.to_latex(float_format="%.0f"))

avg_dom3 = pd.concat([avg_dom, avg_dom2], axis=1)
print(avg_dom3.to_latex(float_format="%.0f"))
