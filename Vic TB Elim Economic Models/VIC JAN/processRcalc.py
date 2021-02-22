# -*- coding: utf-8 -*-
"""
Created on Thu Feb 18 12:28:02 2021

@author: wilsonte
"""

import pandas as pd
from matplotlib import pyplot
import matplotlib.ticker as ticker
import seaborn as sns
#from tqdm import tqdm

def Process(path, name):
    df = pd.read_csv(path + name + '.csv', header=6)
    df = df[['rand_seed', '[step]', 'average_R', 'global_transmissability']]
    lastStep = df['[step]'].max()
    df = df[df['[step]'] == lastStep]
    df = df[['rand_seed', 'average_R', 'global_transmissability']]
    
    df = df.set_index(['rand_seed', 'global_transmissability'])
    
    df = df.unstack(level=-1)
    df.columns = df.columns.get_level_values(1)
    df.to_csv(path + name + '_process.csv')
    df.describe().to_csv(path + name + '_metric.csv')
    print(df.describe())


def ProcessVariableEnd(path, nameList):
    name = nameList[0]
    interestingColumns = ['rand_seed', 'average_R', 'param_policy', 'global_transmissability', 'totalEndCount']
    df = pd.DataFrame(columns=interestingColumns)
    for v in nameList:
        pdf = pd.read_csv(path + v + '.csv', header=6)
        pdf = pdf[interestingColumns]
        df  = df.append(pdf)
    
    df = df.set_index(['rand_seed', 'param_policy', 'global_transmissability'])
    
    df.to_csv(path + name + '_merge.csv')
    
    print(df)
    df = df.unstack(level=-1)
    df = df.unstack(level=-1)
    print(df)
    df.to_csv(path + name + '_process.csv')
    df.describe().to_csv(path + name + '_metric.csv')
    
    #print((df['average_R'] * df['totalEndCount']).sum() / df['totalEndCount'].sum())
    print(df.describe())
    

def MakePlot(path, name):
    df = pd.read_csv(path + name + '.csv', index_col=0, header=[0, 1, 2], skipinitialspace=True)
    df = df.drop('totalEndCount', axis=1, level=0)
    
    transmit_vals = list(dict.fromkeys([v[1] for v in df.columns]))
    policy_vals = list(dict.fromkeys([v[2] for v in df.columns]))
    #print(transmit_vals)

    dataCount = len(df.columns)
    print(policy_vals)
    
    sns.set_theme(style="ticks", palette="pastel")
    sns.set_style("ticks", {"xtick.major.size": 60})
    
    fig, ax = pyplot.subplots(figsize=(48.5, 40))
    plt = sns.boxplot(data=df, fliersize=1.8, showmeans=True,
                      meanprops={"marker":"+","markerfacecolor":"black", "markeredgecolor":"black"})
    #plt = sns.swarmplot(data=df, color=".25")
    plt.set(xlim=(-1, dataCount + 1), ylim=(-0.2, 9.2))
    sns.despine(ax=ax, offset=10)
    
    plt.set_xticklabels([''] * dataCount)
    plt.xaxis.set_major_locator(ticker.FixedLocator([i*len(policy_vals) - 0.5 for i in range(len(transmit_vals))]))
    plt.xaxis.set_minor_locator(ticker.FixedLocator([i*len(policy_vals) + 2.5 for i in range(len(transmit_vals))]))
    plt.xaxis.set_minor_formatter(ticker.FixedFormatter(transmit_vals))
    
    
    for tick in ax.xaxis.get_minor_ticks():
        tick.label.set_fontsize(32) 
        tick.tick1line.set_markersize(0)
        tick.tick2line.set_markersize(0)
        tick.label1.set_horizontalalignment('center')
    
    for tick in ax.yaxis.get_major_ticks():
        tick.label.set_fontsize(32) 
        
    pyplot.xlabel("Transmissability", fontsize=48)
    pyplot.ylabel("R", fontsize=48)
    
    ax.set_yticks(range(10))
    ax.set_yticks([i/5 for i in range(50)], minor=True)
    
    ax.axhline(y=1, linewidth=2.2, zorder=0, color='r')
    ax.axhline(y=2.5, linewidth=2.2, zorder=0, color='r')
    ax.axhline(y=2.5*1.25, linewidth=2.2, zorder=0, color='r')
    ax.axhline(y=2.5*1.5, linewidth=2.2, zorder=0, color='r')
    
    ax.grid(which='minor', alpha=0.4, linewidth=1.5, zorder=-1, axis="y")
    ax.grid(which='major', alpha=0.7, linewidth=2, zorder=-1)

nameNumber = 5
#nameStr = 'COVID SIMULS VIC JAN Vaccination Model R test 7-table' + str(nameNumber)
nameStr = 'headless R test 7-table' + str(nameNumber)

ProcessVariableEnd('Output/R calc test 3/', [nameStr])
MakePlot('Output/R calc test 3/', nameStr + '_process')