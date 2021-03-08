# -*- coding: utf-8 -*-
"""
Created on Mon Feb 15 10:22:33 2021

@author: wilsonte
"""

import math
import pandas as pd
import numpy as np
from tqdm import tqdm
import time
import os

fileCreated = {}

def SplitNetlogoList(chunk, cohorts, name, outputName):
    split_names = [outputName + str(i) for i in range(0, cohorts)]
    chunk[split_names] = chunk[name].str.replace('\[', '').str.replace('\]', '').str.split(' ', expand=True)
    chunk = chunk.drop(name, axis=1)
    return chunk
    
  
def SplitNetlogoNestedList(chunk, cohorts, days, colName, name):
    split_names = [(name, j, i) for j in range(0, days) for i in range(0, cohorts)]
    df = chunk[colName].str.replace('\[', '').str.replace('\]', '').str.split(' ', expand=True)
    df.columns = pd.MultiIndex.from_tuples(split_names, names=['metric', 'day', 'cohort'])
    return df


def OutputToFile(chunk, path, fileAppend):
    # Called like this. Splits each random seed into its own file.
    #for value in chunk.index.unique('rand_seed'):
    #    OutputToFile(chunk.loc[value], filename, value)
    fullFilePath = path + '_' + fileAppend + '.csv'
    if fileCreated.get(fileAppend):
        # Append
        chunk.to_csv(fullFilePath, mode='a', header=False)
    else:
        fileCreated[fileAppend] = True
        chunk.to_csv(fullFilePath) 


def SplitOutDailyData(chunk, cohorts, days, name, filePath, fileAppend):
    columnName = name + '_listOut'
    df = SplitNetlogoNestedList(chunk, cohorts, days, columnName, name)
    OutputToFile(df, filePath, fileAppend)


def Process(chunk: pd.DataFrame, outputStaticData, filename):
    # Drop colums that are probably never useful.
    
    chunk = chunk[[
        '[run number]', 'rand_seed', 'param_policy', 'global_transmissibility',
        'param_vac1_tran_reduct', 'param_vac2_tran_reduct', 'param_vac_uptake',
        'param_trigger_loosen',
        'stage_listOut', 'scalephase', 'cumulativeInfected', 'casesReportedToday',
        'Deathcount', 'totalOverseasIncursions', 'infectArray_listOut', 'recoverArray_listOut',
        'dieArray_listOut', 'age_listOut', 'atsi_listOut', 'morbid_listOut',
    ]]
    
    cohorts = len(chunk.iloc[0].age_listOut.split(' '))
    days = len(chunk.iloc[0].stage_listOut.split(' '))
    
    if outputStaticData:
        staticData = pd.DataFrame(chunk[['age_listOut', 'atsi_listOut', 'morbid_listOut']].transpose()[0])
        staticData = SplitNetlogoList(staticData, cohorts, 0, '').transpose()
        staticData = staticData.rename(columns={'age_listOut': 'age', 'atsi_listOut': 'atsi', 'morbid_listOut': 'morbid'})
        staticData.to_csv(filename + '_static.csv')
        
    
    chunk = chunk.drop(['age_listOut', 'atsi_listOut', 'morbid_listOut'], axis=1)
    chunk = chunk.rename(mapper={'[run number]' : 'run'}, axis=1)
    chunk = chunk.set_index([
        'run', 'rand_seed', 'param_policy', 'global_transmissibility',
        'param_vac1_tran_reduct', 'param_vac2_tran_reduct',
        'param_vac_uptake', 'param_trigger_loosen',
    ])
    #chunk.to_csv('Output/runTry1/wip.csv')
    
    secondaryData = [
        'scalephase', 'cumulativeInfected', 'casesReportedToday',
        'Deathcount', 'totalOverseasIncursions'
    ]
    
    chunk[secondaryData].to_csv(filename + '_secondary.csv')
    chunk = chunk.drop(secondaryData, axis=1)
    
    index = chunk.index.to_frame()
    index['R0'] = index['global_transmissibility'].replace({
        0.34 : 2.5,
        0.45 : 3.125,
        0.54 : 3.75,})
    chunk.index = pd.MultiIndex.from_frame(index)
    
    SplitOutDailyData(chunk, 1, days, 'stage', filename, 'stage')
    SplitOutDailyData(chunk, cohorts, days, 'infectArray', filename, 'infect')
    SplitOutDailyData(chunk, cohorts, days, 'recoverArray', filename, 'recover')
    SplitOutDailyData(chunk, cohorts, days, 'dieArray', filename, 'die')


def ToVisualisation(chunk, filename, append):
    chunk.columns.set_levels(chunk.columns.levels[1].astype(int), level=1, inplace=True)
    chunk.columns.set_levels(chunk.columns.levels[2].astype(int), level=2, inplace=True)
    chunk = chunk.groupby(level=[0, 1], axis=1).sum()
    chunk.sort_values('day', axis=1, inplace=True)
    
    index = chunk.columns.to_frame()
    index['week'] = np.floor((index['day'] + 6)/7)
    
    chunk.columns = index
    chunk.columns = pd.MultiIndex.from_tuples(chunk.columns, names=['metric', 'day', 'week'])
    chunk.columns = chunk.columns.droplevel(level=0)
    chunk = chunk.groupby(level=[1], axis=1).sum()
    
    #chunk.to_csv('Output/runTry1/wip.csv')
    OutputToFile(chunk, filename, append + '_weeklyAgg')
    

def ToVisualisationRollingWeekly(chunk, filename, append):
    chunk.columns.set_levels(chunk.columns.levels[1].astype(int), level=1, inplace=True)
    chunk.columns.set_levels(chunk.columns.levels[2].astype(int), level=2, inplace=True)
    chunk = chunk.groupby(level=[0, 1], axis=1).sum()
    chunk.columns = chunk.columns.droplevel(level=0)
    
    leftPad = [-(i+1) for i in range(6)]
    for v in leftPad:
        chunk[v] = 0
    chunk.sort_values('day', axis=1, inplace=True)
    chunk = chunk.rolling(7, axis=1).mean()
    chunk = chunk.drop(columns = leftPad)
    
    #chunk.to_csv('Output/runTry1/wip.csv')
    OutputToFile(chunk, filename, append + '_rolling_weekly')
    
    
def ProcessRawOutput(outputFile, filelist):
    chunksize = 4 ** 6
    
    firstProcess = True
    for filename in filelist:
        size = os.path.getsize(filename + '.csv')
        expectedRuns = math.round(4 * size / 1046579370)
        for chunk in tqdm(pd.read_csv(filename + '.csv', chunksize=chunksize, header=6), total=expectedRuns):
            Process(chunk, firstProcess, outputFile)
            firstProcess = False


def ProcessFileToVisualisation(filename, append):
    chunksize = 4 ** 6
    for chunk in tqdm(pd.read_csv(filename + '_' + append + '.csv', chunksize=chunksize,
                                  index_col=list(range(9)),
                                  header=list(range(3)),
                                  dtype={'day' : int, 'cohort' : int}),
                      total=16):
        ToVisualisationRollingWeekly(chunk, filename, append)


#ProcessRawOutput('Output/runTry1/processed',
#    ['Output/runTry1/headless MainTest20-table_20',
#    'Output/runTry1/headless MainTest-table_80']
#    )
ProcessFileToVisualisation('Output/runTry1/processed', 'infect') 
ProcessFileToVisualisation('Output/runTry1/processed', 'die')