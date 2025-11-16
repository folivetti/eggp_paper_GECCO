import pandas as pd
import sympy as sym 
import glob 

def model_size(expr):
    """Compute the size of a sympy expression."""
    if expr.is_Atom:
        return 1
    else:
        return 1 + sum(model_size(arg) for arg in expr.args)

datasets = ["1028_SWD", "1193_BNG_lowbwt", "192_vineyard", "522_pm10", "579_fri_c0_250_5", "650_fri_c0_500_50", "1089_USCrime", "1199_BNG_echoMonths", "210_cloud", "557_analcatdata_apnea1", "606_fri_c2_1000_10", "678_visualizing_environmental", "chemical_1_tower", "flow_stress_phip0.1", "friction_stat_one-hot", "nasa_battery_2_20min", "nikuradse_2", "chemical_2_competition",  "friction_dyn_one-hot", "nasa_battery_1_10min", "nikuradse_1"]

# for each dataset ...
for d in datasets:
    # ...and each algorithm...
    print(f"Processing dataset: {d}")
    alg = "PySIPS"
    directory = f"results/{alg}/{d}/*.csv"

    for i,f in enumerate(glob.glob(directory)):
        dfi = pd.read_csv(f)
        sizes = []
        for j, expr in enumerate(dfi['Expression']):
            try:
                symexpr = sym.sympify(expr.replace("_","").replace(")(",")*(").replace("^","**"))
                size = model_size(symexpr)
            except:
                print(f"Could not parse expression: {expr}")
                size = dfi.loc[j, 'size']
            sizes.append(size)
        dfi['size'] = sizes
        dfi.to_csv(f, index=False)
