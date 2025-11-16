import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
import sympy 
from sympy.printing.printer import Printer
from GPZD import GPZGD, model

if len(sys.argv) > 2:
    df = pd.read_csv(f"datasets/srbench/{sys.argv[1]}_train{sys.argv[2]}.csv", dtype=np.float64)
    df_test = pd.read_csv(f"datasets/srbench/{sys.argv[1]}_test{sys.argv[2]}.csv", dtype=np.float64)
else:
    df = pd.read_csv(f"datasets/realworld/{sys.argv[1]}_train.csv", dtype=np.float64)
    df_test = pd.read_csv(f"datasets/realworld/{sys.argv[1]}_test.csv", dtype=np.float64)

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values


reg = GPZGD(pop_size=500, generations=200, opset="ADD,SUB,MUL,DIV,SIN,EXP,LOG,ERC,VAR")
reg.fit(X_train, y_train)

def count_nodes(expression):
    count = 1  # Count the current node
    for arg in expression.args:
        count += count_nodes(arg)
    return count

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
printer = Printer()
string_model = printer.doprint(sympy.sympify(model(reg)))
model_sym = sympy.sympify(model(reg))
nodes = count_nodes(model_sym)

print(f"{ix},{string_model},{nodes},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}")

