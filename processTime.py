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
print(piv)
piv.reset_index(inplace=True)
for alg in ['PySR', 'eggp_mo', 'eggp_so', 'tinyGP', 'Operon']:
    piv[alg] = piv[alg] / piv['Operon']

font = { 'size'   : 20}
matplotlib.rc('font', **font)
piv[['dataset', 'eggp_mo', 'eggp_so', 'tinyGP', 'PySR']].plot.bar(x='dataset', stacked=False, title='Relative time to Operon', figsize=(10,6), width=0.7)
plt.savefig('time.eps', bbox_inches='tight')
font = { 'size'   : 22}
matplotlib.rc('font', **font)
piv[['dataset', 'eggp_mo', 'eggp_so', 'tinyGP', 'PySR']].plot.box(x='dataset', title='Relative time to Operon')
plt.savefig('timeBox.eps', bbox_inches='tight')
