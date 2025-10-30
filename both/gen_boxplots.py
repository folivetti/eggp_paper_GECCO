import pandas as pd 
import matplotlib.pyplot as plt 
import numpy as np 
import seaborn as sns

sns.set_style("whitegrid")

#df = pd.read_csv('perf_pivoted.csv')
df = pd.read_csv('perf.csv')
df = df[df['algorithm'] != 'GPGOMEA']
df = df[df['algorithm'] != 'GPZGD']

def remove_outliers(group):
    Q1 = group['mse_test'].quantile(0.25)
    Q3 = group['mse_test'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    return group[(group['mse_test'] >= lower_bound) & (group['mse_test'] <= upper_bound)]

df_filtered = df.groupby(['dataset', 'algorithm']).apply(remove_outliers).reset_index(drop=True)

g = sns.catplot(
    col='dataset',
    y='mse_test',
    x='algorithm',
    hue='algorithm',
    kind='box',
    col_wrap=4,
    data=df_filtered,
    sharey=False,
    palette="Set2",    # Use a color palette for different groups
    width=0.5,            # Control the width of the boxes
    linewidth=1.5,        # Line thickness
    fliersize=3,          # Size of the outlier markers
    notch=True            # Add a notch for median confidence interval
)

g.map(
    sns.swarmplot,
    'algorithm',
    'mse_test',
    color='black',
    s=5,
    alpha=0.6,
    data=df_filtered.rename(columns={'mse_test': 'Score_for_map'}) # Pass the filtered data back to map
)

plt.savefig('plots/boxplots/boxplot_all_datasets.eps')

'''
algs = list(df.columns[1:])
algs = [alg for alg in algs if alg != 'GPGOMEA' and alg != 'GPZGD']

datasets = np.unique(df['dataset'].values)

df.loc[:,algs] = -df[algs]
for dataset in datasets:
    df_subset = df[df['dataset'] == dataset]
    plt.figure()
    #df_subset.boxplot(column=algs, showfliers=False)
    sns.boxplot(
        x='Group',
        y='Value',
        data=df_long,
        palette="viridis",    # Use a color palette for different groups
        width=0.5,            # Control the width of the boxes
        linewidth=1.5,        # Line thickness
        fliersize=3,          # Size of the outlier markers
        notch=True            # Add a notch for median confidence interval
    )
    plt.savefig(f'plots/boxplots/boxplot_{dataset}.png')
    '''
