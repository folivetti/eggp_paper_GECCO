import pandas as pd 
import matplotlib.pyplot as plt 
import numpy as np 
import seaborn as sns

sns.set_style("whitegrid")

df = pd.read_csv('perf.csv')
algs = ["eggp", "GPZGD", "Operon", "QLattice", "RF", "PySR", "PySIPS", "GPGOMEA", "SymRegg", "neogp", "slim_gsgp", "random"]
datasets = ['192_vineyard',
            '210_cloud',
            '522_pm10',
            '557_analcatdata_apnea1',
            '579_fri_c0_250_5',
            '606_fri_c2_1000_10',
            '650_fri_c0_500_50',
            '678_visualizing_environmental',
            '1028_SWD',
            '1089_USCrime',
            '1193_BNG_lowbwt',
            '1199_BNG_echoMonths',
            'chemical_1_tower',
            'chemical_2_competition',
            'flow_stress_phip0.1',
            'friction_dyn_one-hot',
            'friction_stat_one-hot',
            'nasa_battery_1_10min',
            'nasa_battery_2_20min',
            'nikuradse_1',
            'nikuradse_2'
           ]

def remove_outliers(group):
    Q1 = group['mse_test'].quantile(0.25)
    Q3 = group['mse_test'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = 0 # Q1 - 1.5 * IQR
    upper_bound = Q3 # + 1.5 * IQR
    # Filter the group to remove outliers values between the bounds of mse_test
    return group[(group['mse_test'] >= lower_bound) & (group['mse_test'] <= upper_bound)]

#df_filtered = df.groupby(['dataset', 'algorithm']).apply(remove_outliers).reset_index(drop=True)
df_filtered = df.groupby(['dataset', 'algorithm']).apply(lambda x: x).reset_index(drop=True)# [algs]
sns.set(font_scale=1.5)
g = sns.catplot(
    col='dataset',
    y='mse_test',
    x='algorithm',
    hue='algorithm',
    kind='box',
    order=algs,
    col_order=datasets,
    col_wrap=5,
    data=df_filtered,
    sharey=False,
    palette="Set2",    # Use a color palette for different groups
    width=0.5,            # Control the width of the boxes
    linewidth=1.5,        # Line thickness
    fliersize=3,          # Size of the outlier markers
    notch=True            # Add a notch for median confidence interval
)
g.tick_params(axis='x', rotation=90)
g.set_titles("{col_name}")
for ax in g.axes.flat:
    ax.set_xlabel("")
# set y-axis upper bound to the group 3rd quartile 
for ax in g.axes.flat:
    dataset = ax.get_title()
    # get the worst 'mse_test' of the best algorithm for that dataset 
    data = df_filtered[df_filtered['dataset'] == dataset]
    best_alg = data.groupby('algorithm')['mse_test'].max().idxmin()
    worst_mse = data[data['algorithm'] == best_alg]['mse_test'].max()

    data = df_filtered[df_filtered['dataset'] == dataset]['mse_test']
    Q = 1.5*worst_mse # data.quantile(0.9)
    min_y = data.min()*0.85
    ax.set_ylim(min_y, Q)
plt.savefig('plots/boxplots/boxplot_all_datasets.eps', bbox_inches='tight', format='eps')

