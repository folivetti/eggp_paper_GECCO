import sys 
import numpy as np 
import pandas as pd 
from sklearn.metrics import r2_score, make_scorer, mean_squared_error
from sklearn.ensemble import RandomForestRegressor

print("Id,Expression,max_features,max_samples,MSE_train,OOB_score,MSE_test,R2_train,R2_test")
for max_features, max_samples in [
        (mf, ms)
        for mf in ["sqrt", "log2", 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        for ms in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
    ]:
    
    reg = RandomForestRegressor(n_estimators=500, max_features=max_features, max_samples=max_samples, oob_score=True)

    df = pd.read_csv(f"datasets/{sys.argv[1]}_train.csv")
    df_test = pd.read_csv(f"datasets/{sys.argv[1]}_test.csv")

    X_train, y_train = df.loc[:, df.columns != 'target'].values, df.target.values
    X_test,  y_test  = df_test.loc[:, df_test.columns != 'target'].values, df_test.target.values

    reg.fit(X_train, y_train)

    expr = "X"
    y_hat = reg.predict(X_train)
    y_hat_test = reg.predict(X_test)
    mse_train = mean_squared_error(y_train, y_hat)
    oob_score = reg.oob_score_
    mse_test  = mean_squared_error(y_test, y_hat_test)
    r2_train = r2_score(y_train, y_hat)
    r2_test  = r2_score(y_test, y_hat_test)

    ix = f"maxfeat{max_features}_maxsampl{max_samples}"
    print(f"{ix},{expr},{max_features},{max_samples},{mse_train},{oob_score},{mse_test},{r2_train},{r2_test}")
