import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
from pysips import PysipsRegressor
import sympy 

reg = PysipsRegressor(
    operators=['+', '-', '*', '/', 'pow', 'exp', 'sin', 'log', 'sqrt'],
    max_complexity=50,
    max_equation_evals=100000,
    num_particles=int(sys.argv[3]),
    num_mcmc_samples=int(sys.argv[2]),
)

df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

reg.fit(X_train, y_train)

eqs = reg.get_models()[0] 

print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
ix = 0
y_hat = reg.predict(X_train)
y_hat_test = reg.predict(X_test)
has_nan = np.any(np.isnan(y_hat))
has_nan_test = np.any(np.isnan(y_hat_test))
mse_train = np.inf if has_nan else mean_squared_error(y_train, y_hat)
mse_test  = np.inf if has_nan_test else mean_squared_error(y_test, y_hat_test)
r2_train = -np.inf if has_nan else r2_score(y_train, y_hat)
r2_test  = -np.inf if has_nan else r2_score(y_test, y_hat_test)
eq = reg.best_model_
print(f"{ix},{eq},{eq.get_complexity()},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}")
'''
for ix in range(len(eqs)):
    y_hat = eqs[ix].evaluate_equation_at(X_train)
    y_hat_test = eqs[ix].evaluate_equation_at(X_test)
    has_nan = np.any(np.isnan(y_hat))
    has_nan_test = np.any(np.isnan(y_hat_test))
    mse_train = np.inf if has_nan else mean_squared_error(y_train, y_hat)
    mse_test  = np.inf if has_nan_test else mean_squared_error(y_test, y_hat_test)
    r2_train = -np.inf if has_nan else r2_score(y_train, y_hat)
    r2_test  = -np.inf if has_nan else r2_score(y_test, y_hat_test)

    print(f"{ix},{eqs[ix]},{eqs[ix].get_complexity()},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}")
'''
