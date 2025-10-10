import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
from pygpg.sk import GPGRegressor
from pygpg.complexity import compute_complexity

import sympy 

reg = GPGRegressor(
    fset="+,-,*,/,sin,log,sqrt",
    d=5,
    pop=int(sys.argv[3]),
    g=int(sys.argv[2]),
    t=-1,
    e=-1
)

df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

reg.fit(X_train, y_train)

print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
y_hat = reg.predict(X_train)
y_hat_test = reg.predict(X_test)
has_nan = np.any(np.isnan(y_hat))
has_nan_test = np.any(np.isnan(y_hat_test))
mse_train = np.inf if has_nan else mean_squared_error(y_train, y_hat)
mse_test  = np.inf if has_nan_test else mean_squared_error(y_test, y_hat_test)
r2_train = -np.inf if has_nan else r2_score(y_train, y_hat)
r2_test  = -np.inf if has_nan else r2_score(y_test, y_hat_test)
ix = 0 

print(f'{ix},{reg.model},{compute_complexity(reg.model, complexity_metric="node_count")},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}')
