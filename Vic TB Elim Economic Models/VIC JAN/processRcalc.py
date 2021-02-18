# -*- coding: utf-8 -*-
"""
Created on Thu Feb 18 12:28:02 2021

@author: wilsonte
"""


import pandas as pd
from tqdm import tqdm

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
    
def ProcessVariableEnd(path, name):
    df = pd.read_csv(path + name + '.csv', header=6)
    df = df[['rand_seed', 'average_R', 'global_transmissability', 'totalEndCount']]
    df = df[['rand_seed', 'average_R', 'global_transmissability', 'totalEndCount']]
    
    df = df.set_index(['rand_seed', 'global_transmissability'])
    
    df = df.unstack(level=-1)
    df.to_csv(path + name + '_process.csv')
    df.describe().to_csv(path + name + '_metric.csv')
    
    print((df['average_R'] * df['totalEndCount']).sum() / df['totalEndCount'].sum())
    print(df.describe())
    
    
Process('Output/R calc test 2/', 'headless R Test 4-table')