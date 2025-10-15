import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
import feyn
import sympy 
from sympy.printing.printer import Printer

reg = feyn.QLattice()

df = pd.read_csv(f"datasets/{sys.argv[1]}_train{sys.argv[3]}.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test{sys.argv[3]}.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

feyn.validate_data(df, 'regression', 'target')
priors = feyn.tools.estimate_priors(df, 'target')
reg.update_priors(priors)
n_models = 0
models = []
while n_models < int(sys.argv[2]):
    new_sample = reg.sample_models(df, 'target', 'regression', None, 10, None, ["add", "multiply", "squared", "exp", "inverse", "log"]) #, ["add", "multiply", "pow", "exp", "sine", "log", "sqrt"])
    n_models += len(new_sample)
    models += new_sample
    models = feyn.fit_models(models, data=df, threads=1)
    models = feyn.prune_models(models)
    reg.update(models)
eqs = feyn.get_diverse_models(models)


def count_nodes(expression):
    count = 1  # Count the current node
    for arg in expression.args:
        count += count_nodes(arg)
    return count

print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
for ix in range(len(eqs)):
    y_hat = eqs[ix].predict(df)
    y_hat_test = eqs[ix].predict(df_test)
    has_nan = np.any(np.isnan(y_hat))
    has_nan_test = np.any(np.isnan(y_hat_test))
    mse_train = np.inf if has_nan else mean_squared_error(y_train, y_hat)
    mse_test  = np.inf if has_nan_test else mean_squared_error(y_test, y_hat_test)
    r2_train = -np.inf if has_nan else r2_score(y_train, y_hat)
    r2_test  = -np.inf if has_nan else r2_score(y_test, y_hat_test)
    printer = Printer()
    string_model = printer.doprint(eqs[ix].sympify())
    nodes = count_nodes(eqs[ix].sympify())

    print(f"{ix},{string_model},{nodes},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}")

