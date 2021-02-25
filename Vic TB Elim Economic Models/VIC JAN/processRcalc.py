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
    df = df[['rand_seed', '[step]', 'average_R', 'global_transmissibility']]
    lastStep = df['[step]'].max()
    df = df[df['[step]'] == lastStep]
    df = df[['rand_seed', 'average_R', 'global_transmissibility']]
    
    df = df.set_index(['rand_seed', 'global_transmissibility'])
    
    df = df.unstack(level=-1)
    df.columns = df.columns.get_level_values(1)
    df.to_csv(path + name + '_process.csv')
    df.describe().to_csv(path + name + '_metric.csv')
    print(df.describe())


def ProcessVariableEnd(path, nameList):
    name = nameList[0]
    interestingColumns = [
        'rand_seed', 'average_R', 'param_policy', 
        'global_transmissibility', 'totalEndCount', 'slopeAverage',
        'trackAverage', 'infectedTrackAverage', 'testName',
    ]
    df = pd.DataFrame(columns=interestingColumns)
    for v in nameList:
        pdf = pd.read_csv(path + v + '.csv', header=6)
        if 'testName' not in pdf.columns:
            interestingColumns = filter(lambda x: x != 'testName', interestingColumns)
        pdf = pdf[interestingColumns]
        df  = df.append(pdf)
    
    desiredIndex = ['rand_seed', 'param_policy', 'global_transmissibility']
    inTest = ('testName' in df.columns and (len(df['testName'].unique()) > 1))
    if inTest:
        desiredIndex.append('testName')
        df['testName'] = df['testName'].str.replace('EssWork', 'Ework')
    else:
        df = df.drop(columns=['testName'])
    
    df = df.set_index(desiredIndex)
    
    df.to_csv(path + name + '_merge.csv')
    
    # Sometimes the random numbers collide.
    df = df[~df.index.duplicated(keep='first')]
    
    df = df.unstack(level=-1)
    df = df.unstack(level=-1)
    df.to_csv(path + name + '_process.csv')
    df_desc = df.describe()
    df_desc.to_csv(path + name + '_metric.csv')
    
    #print((df['average_R'] * df['totalEndCount']).sum() / df['totalEndCount'].sum())
    print(df.describe())
    

def MakePlot(path, name, varName,
        yDomain=(-0.2, 9.2),
        ymajticks=False,
        yminticks=False,
        hlines=False,
        width=48.5
        ):
    df = pd.read_csv(path + name + '.csv', index_col=0, header=[0, 1, 2], skipinitialspace=True)
    
    unwantedTop = list(dict.fromkeys([v[0] for v in df.columns if v[0] != varName]))
    df = df.drop(unwantedTop, axis=1, level=0)
    
    xLabel = df.columns.names[1]
    transmit_vals = list(dict.fromkeys([v[1] for v in df.columns]))
    policy_vals = list(dict.fromkeys([v[2] for v in df.columns]))
    #print(transmit_vals)

    dataCount = len(df.columns)
    
    sns.set_theme(style="ticks", palette="pastel")
    sns.set_style("ticks", {"xtick.major.size": 60})
    
    fig, ax = pyplot.subplots(figsize=(width, 40))
    plt = sns.boxplot(data=df, fliersize=1.8, showmeans=True,
                      meanprops={"marker":"+","markerfacecolor":"black", "markeredgecolor":"black"})
    #plt = sns.swarmplot(data=df, color=".25")
    plt.set(xlim=(-1, dataCount + 1), ylim=yDomain)
    sns.despine(ax=ax, offset=10)
    
    plt.set_xticklabels([''] * dataCount)
    plt.xaxis.set_major_locator(ticker.FixedLocator([i*len(policy_vals) - 0.5 for i in range(len(transmit_vals))]))
    plt.xaxis.set_minor_locator(ticker.FixedLocator([(i + 0.5)*len(policy_vals) - 0.5 for i in range(len(transmit_vals))]))
    plt.xaxis.set_minor_formatter(ticker.FixedFormatter(transmit_vals))
    
    for tick in ax.xaxis.get_minor_ticks():
        tick.label.set_fontsize(32) 
        tick.tick1line.set_markersize(0)
        tick.tick2line.set_markersize(0)
        tick.label1.set_horizontalalignment('center')
    
    for tick in ax.yaxis.get_major_ticks():
        tick.label.set_fontsize(32) 
        
    pyplot.xlabel(xLabel, fontsize=48)
    pyplot.ylabel(varName, fontsize=48)
    
    if ymajticks:
        ax.set_yticks(ymajticks)
    if yminticks:
        ax.set_yticks(yminticks, minor=True)
    
    if hlines:
        for v in hlines:
            ax.axhline(y=v, linewidth=2.2, zorder=0, color='r')
    
    ax.grid(which='minor', alpha=0.4, linewidth=1.5, zorder=-1, axis="y")
    ax.grid(which='major', alpha=0.7, linewidth=2, zorder=-1)

nameNumber = '16'
namePath = 'R calc 4'
#nameStr = 'COVID SIMULS VIC JAN Vaccination Model R test 7-table' + str(nameNumber)
nameStr = 'headless find_2.5-table' + nameNumber
#nameStr = 'headless find_2.5 high track-table' + nameNumber

#namePath = 'StageTest'
#nameStr = 'headless stageTest-table_3'

#namePath = 'R regress'
#nameStr = 'COVID SIMULS VIC JAN Vaccination Model singleTest-table'


#ProcessVariableEnd('Output/' + namePath + '/', [nameStr])
#MakePlot('Output/' + namePath + '/', nameStr + '_process', 'slopeAverage',
#    yDomain=(-0.3, 0.3),
#    ymajticks=[i/10 - 0.3 for i in range(7)],
#    yminticks=[i/50 - 0.3 for i in range(35)]
#)
MakePlot('Output/' + namePath + '/', nameStr + '_process', 'average_R',
    yDomain=(-0.2, 6.2),
    ymajticks=range(7),
    yminticks=[i/5 for i in range(35)],
    hlines=[1, 2.5, 2.5*1.25, 2.5*1.5],
    width=100
)
#MakePlot('Output/' + namePath + '/', nameStr + '_process', 'trackAverage',
#    yDomain=(0, 1),
#    ymajticks=[i/5 for i in range(5)],
#    yminticks=[i/25 for i in range(25)]
#)
#MakePlot('Output/' + namePath + '/', nameStr + '_process', 'infectedTrackAverage',
#    yDomain=(0, 1),
#    ymajticks=[i/5 for i in range(5)],
#    yminticks=[i/25 for i in range(25)]
#)