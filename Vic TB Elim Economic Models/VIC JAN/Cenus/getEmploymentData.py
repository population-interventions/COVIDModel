# -*- coding: utf-8 -*-
"""
Created on Tue Feb 23 16:11:43 2021

@author: wilsonte
"""


import pandas as pd


def Process(name):
    df = pd.read_csv(name + '.csv', header=0)
    df = df.drop(['MEASURE', 'Sex', 'TIME', 'Time',
                  'Flag Codes', 'Flags', 'Frequency',
                  'Region Type', 'LGA 2011', 'Labour Force Status',
                  'STATE', 'REGIONTYPE', 'FREQUENCY',
                  'State', 'REGION', 'Age'], axis=1)
    
    df_tot = df[(df['LFSP'] == 'TOT')]
    df_tot = df_tot.groupby(['AGE', 'LFSP']).sum()
    df_tot = df_tot.sum(level=[0], axis=0)
    print(df_tot)
    
    df_un = df[(df['LFSP'] == '7') | (df['LFSP'] == 'UEMP')]
    df_un = df_un.groupby(['AGE', 'LFSP']).sum()
    df_un = df_un.sum(level=[0], axis=0)
    
    print(1 - df_un / df_tot)
    
    
    
Process('ABS_CENSUS2011_B42_LGA_23022021160531450')