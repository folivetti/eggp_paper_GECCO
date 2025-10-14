import pandas as pd 
import sys 

df = pd.read_csv("perf.csv")
df['dataset_run'] = df['dataset'] + "==" + df['run'].astype(str)
df['mse_test'] = -1 * df['mse_test']  

if sys.argv[1] == "R2":
    df_pivoted = df.pivot(index='dataset_run', columns='algorithm', values='r2_test').reset_index()
else:
    df_pivoted = df.pivot(index='dataset_run', columns='algorithm', values='mse_test').reset_index()

df_pivoted['dataset'] = df_pivoted['dataset_run'].apply(lambda x: x.split('==')[0])
df_pivoted = df_pivoted.drop(columns=['dataset_run'])

cols = df_pivoted.columns.tolist() 
cols = cols[-1:] + cols[:-1]
df_pivoted[cols].to_csv(f"perf_pivoted.csv", index=False)
