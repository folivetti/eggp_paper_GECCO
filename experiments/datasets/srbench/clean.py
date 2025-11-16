import glob
import pandas as pd 

for f in glob.glob("*_train*.csv"):
    df = pd.read_csv(f)
    if df.shape[0] > 1000:
        # sample 1000 random rows
        df = df.sample(1000)
        df.to_csv(f, index=False)
