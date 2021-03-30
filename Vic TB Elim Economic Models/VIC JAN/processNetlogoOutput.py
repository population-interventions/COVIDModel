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
        'Deathcount', 'totalOverseasIncursions', 'infectNoVacArray_listOut', 'infectVacArray_listOut',
        'age_listOut', 'atsi_listOut', 'morbid_listOut',
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
        0.43 : 3.125,
        0.54 : 3.75,})
    chunk.index = pd.MultiIndex.from_frame(index)
    
    SplitOutDailyData(chunk, 1, days, 'stage', filename, 'stage')
    SplitOutDailyData(chunk, cohorts, days, 'infectNoVacArray', filename, 'infectNoVac')
    SplitOutDailyData(chunk, cohorts, days, 'infectVacArray', filename, 'infectVac')


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
    chunksize = 4 ** 7
    
    firstProcess = True
    for filename in filelist:
        size = os.path.getsize(filename + '.csv')
        expectedRuns = math.floor(size / 846579370)
        for chunk in tqdm(pd.read_csv(filename + '.csv', chunksize=chunksize, header=6), total=expectedRuns):
            Process(chunk, firstProcess, outputFile)
            firstProcess = False


def ProcessFileToVisualisation(filename, append):
    chunksize = 4 ** 7
    for chunk in tqdm(pd.read_csv(filename + '_' + append + '.csv', chunksize=chunksize,
                                  index_col=list(range(9)),
                                  header=list(range(3)),
                                  dtype={'day' : int, 'cohort' : int}),
                      total=4):
        #ToVisualisationRollingWeekly(chunk, filename, append)
        ToVisualisation(chunk, filename, append)


def RemoveDuplicates(filename):
    df = pd.read_csv(filename + '.csv', index_col=list(range(9)),
                                  header=list(range(3)),
                                  dtype={'day' : int, 'cohort' : int})
    df = df[~df.index.droplevel(level=0).duplicated(keep='first')]
    df.to_csv(filename + '_unique.csv')


def AddFiles(directory, file1, file2, outputName, append):
    df1 = pd.read_csv(directory + file1 + '.csv', index_col=list(range(9)),
                                  header=list(range(1)))
    df2 = pd.read_csv(directory + file2 + '.csv', index_col=list(range(9)),
                                  header=list(range(1)))
    OutputToFile(df1 + df2, directory + outputName, append)
    
    new_df = (df1 + df2)
    old_df = pd.read_csv('Output/runTry3/processed_infect_unique_weeklyAgg.csv',
                         index_col=list(range(9)),
                         header=list(range(1)))
    print(new_df)
    print(old_df)
    print(new_df - old_df)
    OutputToFile(new_df, directory + outputName, 'NEW')
    OutputToFile(old_df, directory + outputName, 'OLD')
    OutputToFile(new_df - df1, directory + outputName, 'sanity_test')


def AverageRuns(directory, file):
    df = pd.read_csv(directory + file + '.csv', index_col=list(range(9)),
                                  header=list(range(1)))
    df = df.groupby(level=[2, 3, 4, 5, 6, 7, 8], axis=0).mean()
    
    OutputToFile(df, directory + file + '_average_runs', 'aa')
    df = df[[str(i + 14) + '.0' for i in range(26)]]
    df = df.transpose().describe().transpose()
    OutputToFile(df, directory + file + '_stage2_means', 'aaa')
    

def AverageRunsStages(directory, file):
    df = pd.read_csv(directory + file + '.csv', index_col=list(range(9)),
                                  header=list(range(3)))
    df = df.apply(lambda c: [1 if x > 2 else 0 for x in c])
    df = df.groupby(level=[2, 3, 4, 5, 6, 7, 8], axis=0).mean()
    
    df = df.droplevel([0, 2], axis=1)
    df = df[[str(i + 81) for i in range(181)]]
    OutputToFile(df, directory + file + '_stage2_stages_mean', 'test')
    df = df.transpose().describe().transpose()
    df = df[['mean']]
    df = df.reset_index()
    df = df[df['param_vac1_tran_reduct'] == df['param_vac2_tran_reduct']]
    df = df.drop(columns=['param_vac2_tran_reduct', 'global_transmissibility'])
    df = df.rename(columns={'param_vac1_tran_reduct' : 'param_vac_tran_reduct'})
    
    df['param_vac_uptake'] = df['param_vac_uptake'].replace({
        60 : '60',
        75 : '075',
        90 : '0090',
    })
    
    df = df.set_index(['param_policy', 'param_vac_tran_reduct', 'R0',
                       'param_trigger_loosen', 'param_vac_uptake'])
    df = df.unstack(['param_policy', 'param_vac_tran_reduct'])
    OutputToFile(df, directory + file + '_stage2_stages_mean', 'aaa')


directory = 'Output/runTry5/'
ProcessRawOutput(directory + 'processed',
    [directory + 'mergedresult']
    )
##RemoveDuplicates(directory + 'processed_infectNoVac')
##RemoveDuplicates(directory + 'processed_infectVac')
##RemoveDuplicates(directory + 'processed_stage')
ProcessFileToVisualisation(directory + 'processed', 'infectNoVac') 
ProcessFileToVisualisation(directory + 'processed', 'infectVac')
AddFiles(directory, 'processed_infectNoVac_weeklyAgg',
    'processed_infectVac_weeklyAgg', 'processed_infect_unique', 'weeklyAgg')
AverageRuns(directory, 'processed_infect_unique_weeklyAgg')
AverageRunsStages(directory, 'processed_stage')