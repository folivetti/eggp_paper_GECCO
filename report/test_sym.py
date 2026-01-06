import sympy as sym 
from sympy import symbols, sin, log, Add, Mul, Pow, Function

def model_size(expr):
    """Compute the size of a sympy expression."""
    if expr.is_Atom:
        return 1
    else:
        return 1 + sum(model_size(arg) for arg in expr.args)

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

model = sym.sympify("sin(x) + x**2 + log(y*z)")
size = model_size(model)
size2 = count_nodes(model)
print(f"{model} size: {size} or {size2}")
