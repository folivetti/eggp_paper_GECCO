import sys
import numpy as np
import pandas as pd
from pyoperon.sklearn import SymbolicRegressor
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
from pyoperon import R2, MSE, InfixFormatter, FitLeastSquares, Interpreter
import sympy

reg = SymbolicRegressor(
        allowed_symbols= "add,sub,mul,div,exp,logabs,pow,sqrtabs,abs,sin,constant,variable",
        crossover_probability= 0.9,
        mutation_probability= 0.3,
        female_selector= "tournament",
        generations=200,
        optimizer_iterations=100,
        optimizer='lm',
        male_selector= "tournament",
        max_depth=10,
        max_length=33,
        objectives= ['mse', 'length' ],
        pool_size=500,
        population_size=500,
        reinserter= "keep-best",
        tournament_size=5,
        max_evaluations=int(1e10),
        )

df = pd.read_csv(f"datasets/{sys.argv[1]}_train{sys.argv[2]}.csv")
df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test{sys.argv[2]}.csv")

X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values
reg.fit(X_train, y_train)


print("Id,Expression,size,MSE_train,MSE_test,nll_train,nll_test,R2_train,R2_test")
for i, model in enumerate(reg.pareto_front_):
        y_hat = reg.evaluate_model(model['tree'], X_train)
        y_hat_test = reg.evaluate_model(model['tree'], X_test)
        print(f"0,{model['model']},{model['complexity']},{mean_squared_error(y_train,y_hat)},{mean_squared_error(y_test,y_hat_test)},{mean_squared_error(y_train, y_hat)},{mean_squared_error(y_test,y_hat_test)},{r2_score(y_train,y_hat)},{r2_score(y_test,y_hat_test)}")
