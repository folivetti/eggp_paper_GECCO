import pandas as pd 
import matplotlib.pyplot as plt 
import matplotlib 

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42
font = { 'size'   : 22}

matplotlib.rc('font', **font)

df = pd.read_csv("time.csv")

# create a pivot table where the index is the dataset oclumn and the columns are the algorithm 
# and the vvalue is the time but dividied by the time of 'Operon' algorithm 
piv = df.pivot_table(index='dataset', columns='algorithm', values='time', aggfunc='mean')
# flatten pivot table
algs = ["eggp", "GPZGD", "QLattice", "PySR", "PySIPS", "SymRegg", "GPGOMEA", "slim_gsgp"]
piv.reset_index(inplace=True)
for alg in algs:
    piv[alg] = piv[alg] / piv['Operon']

font = { 'size'   : 20}
matplotlib.rc('font', **font)
piv[['dataset'] + algs].plot.bar(x='dataset', stacked=False, title='Relative time to Operon', figsize=(10,6), width=0.7)
plt.savefig('plots/time.eps', bbox_inches='tight')
font = { 'size'   : 22}
matplotlib.rc('font', **font)
piv[['dataset'] + algs].plot.box(x='dataset', title='Relative time to Operon', rot=90, logy=True)
plt.savefig('plots/timeBox.eps', bbox_inches='tight')
