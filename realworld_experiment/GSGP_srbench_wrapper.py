import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
from slim_gsgp.main_slim import slim 
from slim_gsgp.utils.utils import train_test_split 
import torch
import sympy 

df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv", dtype=np.float64)
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv", dtype=np.float64)

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

X_train = torch.tensor(X_train)
y_train = torch.tensor(y_train)

X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, p_test=0.4)

X_test = torch.tensor(X_test)
y_test = torch.tensor(y_test)

reg = slim(X_train=X_train, y_train=y_train,
                  X_test=X_val, y_test=y_val,
                  slim_version='SLIM*ABS', pop_size=int(sys.argv[3]), n_iter=int(sys.argv[2]),
                  tree_functions=['add', 'subtract', 'multiply', 'divide'],
                  ms_lower=0, ms_upper=1, p_inflate=0.5, verbose=0)

print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
y_hat = reg.predict(X_train)
y_hat_test = reg.predict(X_test)
has_nan = np.any(np.isnan(y_hat.numpy()))
has_nan_test = np.any(np.isnan(y_hat_test.numpy()))
mse_train = np.inf if has_nan else mean_squared_error(y_train, y_hat)
mse_test  = np.inf if has_nan_test else mean_squared_error(y_test, y_hat_test)
r2_train = -np.inf if has_nan else r2_score(y_train, y_hat)
r2_test  = -np.inf if has_nan else r2_score(y_test, y_hat_test)
ix = 0 

print(f'{ix},"{reg.get_tree_representation()}",{reg.nodes_count},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}')
