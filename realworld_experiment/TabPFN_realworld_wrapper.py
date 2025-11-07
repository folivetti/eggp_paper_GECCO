import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error

from tabpfn_client import init, TabPFNRegressor

reg = TabPFNRegressor()

print("Id,Expression,size,MSE_train,MSE_test,R2_train,R2_test")
df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

reg.fit(X_train, y_train)

expr = "X"
y_hat = reg.predict(X_train)
y_hat_test = reg.predict(X_test)
mse_train = mean_squared_error(y_train, y_hat)
mse_test  = mean_squared_error(y_test, y_hat_test)
r2_train = r2_score(y_train, y_hat)
r2_test  = r2_score(y_test, y_hat_test)
max_features = 10000000

ix = 0
print(f"{ix},{expr},{max_features},{mse_train},{mse_test},{r2_train},{r2_test}")
