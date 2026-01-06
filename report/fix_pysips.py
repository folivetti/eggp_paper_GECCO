import pandas as pd
import sympy as sym 
import glob 

def count_nodes(expr):
    """
    Counts nodes in a SymPy expression to match a syntax tree perspective.
    
    Rules:
    1. Atoms (Symbols, Numbers): 1 node.
    2. Binary Ops (Add, Mul): Treated as a chain of binary operations. 
       A sum of N terms adds (N-1) operation nodes.
    3. Pow: 1 operation node.
    4. Functions (sin, log): 2 nodes (1 for the implicit 'Call' + 1 for the Function Name).
    """
    
    # Base case: Atoms (leaves of the tree)
    if expr.is_Atom:
        return 1

    # Recursive step: Sum up nodes of all children first
    children_nodes = sum(count_nodes(arg) for arg in expr.args)
    
    # Add internal nodes based on the type of operator
    if expr.is_Add or expr.is_Mul:
        # An operator with N arguments represents N-1 binary operations
        # e.g., a + b + c is (a + b) + c -> 2 '+' nodes
        internal_nodes = len(expr.args) - 1
        return internal_nodes + children_nodes

    elif expr.is_Pow:
        # Power is strictly binary: base ** exp -> 1 node
        return 1 + children_nodes

    else:
        # Fallback for other operations (Relational, etc.): count as 1 op
        return 1 + children_nodes

datasets = ["1028_SWD", "1193_BNG_lowbwt", "192_vineyard", "522_pm10", "579_fri_c0_250_5", "650_fri_c0_500_50", "1089_USCrime", "1199_BNG_echoMonths", "210_cloud", "557_analcatdata_apnea1", "606_fri_c2_1000_10", "678_visualizing_environmental", "chemical_1_tower", "flow_stress_phip0.1", "friction_stat_one-hot", "nasa_battery_2_20min", "nikuradse_2", "chemical_2_competition",  "friction_dyn_one-hot", "nasa_battery_1_10min", "nikuradse_1"]

# for each dataset ...
for d in datasets:
    # ...and each algorithm...
    print(f"Processing dataset: {d}")
    alg = "PySIPS_finetuned"
    directory = f"results/{alg}/{d}/*.csv"

    for i,f in enumerate(glob.glob(directory)):
        dfi = pd.read_csv(f)
        sizes = []
        for j, expr in enumerate(dfi['Expression']):
            try:
                symexpr = sym.sympify(expr.replace("_","").replace(")(",")*(").replace("^","**"))
                size = count_nodes(symexpr)
            except:
                print(f"Could not parse expression: {expr}")
                size = dfi.loc[j, 'size']
            sizes.append(size)
        dfi['size'] = sizes
        dfi.to_csv(f, index=False)
