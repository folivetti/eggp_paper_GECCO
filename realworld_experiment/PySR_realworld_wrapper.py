import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
import juliapkg
juliapkg.require_julia("~1.10")
from pysr import PySRRegressor
import sympy 

reg = PySRRegressor(
        maxsize=int(sys.argv[4]),
        maxdepth=10,
        niterations=int(sys.argv[2]),
        populations=10,
        population_size=int(sys.argv[3]),
        binary_operators=["+","-","*","/","powabs(x,y) = abs(x)^y"],
        unary_operators=["exp","sin","log","sqrtabs(x) = sqrt(abs(x))"],
        crossover_probability=0.9,
        elementwise_loss="L2DistLoss()",
        optimizer_iterations=50,
        optimizer_nrestarts=2,
        tournament_selection_n= 5,
        extra_sympy_mappings={"sqrtabs": lambda x: sympy.sqrt(abs(x)), "powabs": lambda x, y: abs(x)**y},
        model_selection="accuracy",
        parallelism="serial",
        verbosity=0
        )

df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

reg.fit(X_train, y_train)
#print(reg)

eqs = reg.equations_
eq = eqs.iloc[eqs.loss.argmin(), 2]
ix =eqs.loss.argmin()

print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
for ix in range(len(eqs)):
    y_hat = reg.predict(X_train, index=ix)
    y_hat_test = reg.predict(X_test, index=ix)
    mse_train = mean_squared_error(y_train, y_hat)
    mse_test  = mean_squared_error(y_test, y_hat_test)
    r2_train = r2_score(y_train, y_hat)
    r2_test  = r2_score(y_test, y_hat_test)

    print(f"{ix},{eqs.loc[ix,'equation']},{eqs.loc[ix, 'complexity']},{mse_train},{mse_test},{mse_train},{mse_test},{r2_train},{r2_test}")
