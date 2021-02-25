# -*- coding: utf-8 -*-
"""
Created on Mon Feb 15 10:22:33 2021

@author: wilsonte
"""

import pandas as pd
from tqdm import tqdm

fileCreated = {}

def SplitNetlogoList(chunk, cohorts, name, outputName):
    split_names = [outputName + str(i) for i in range(0, cohorts)]
    chunk[split_names] = chunk[name].str.replace('\[', '').str.replace('\]', '').str.split(' ', expand=True)
    chunk = chunk.drop(name, axis=1)
    return chunk
    

def OutputToFile(chunk, filename):
    if fileCreated.get(filename):
        # Append
        chunk.to_csv('Output/halfDataTest/process/' + str(filename) + '.csv', mode='a', header=False)
    else:
        fileCreated[filename] = True
        chunk.to_csv('Output/halfDataTest/process/' + str(filename) + '.csv')
    

def Process(chunk: pd.DataFrame, outputStaticData):
    # Drop colums that are probably never useful.
    chunk = chunk.drop([
        'age_isolation', 'app_uptake', 'assignappess', 'available_resources', 'basestage', 'bed_capacity', 'care_attitude',
        'complacency', 'complacency_bound', 'cruise', 'days_of_cash_reserves', 'diffusion_adjustment', 'end_day', 'essential_workers',
        'ewappuptake', 'feartrigger', 'fourtothree', 'freewheel', 'goldstandard', 'hospital_beds_in_australia', 'household_attack',
        'icu_beds_in_australia', 'icu_required', 'incursionrate', 'initial', 'initial_cases', 'initialassociationstrength',
        'initialscale', 'isolate', 'judgeday1', 'judgeday1_d', 'judgeday2', 'judgeday2_d', 'judgeday3', 'judgeday3_d', 'judgeday4',
        'judgeday4_d', 'link_switch', 'lockdown_off', 'lowerstudentage', 'mask_wearing', 'maskpolicy', 'maxstage', 'maxv',
        'mean_individual_income', 'media_exposure', 'minv', 'onetotwo', 'onetozero', 'os_import_post_proportion',
        'os_import_proportion', 'os_import_switch', 'outside', 'outsiderisk', 'phwarnings', 'policytriggeron', 'population',
        'productionrate', 'profile_on', 'proportion_people_avoid', 'proportion_time_avoid', 'quarantine_spaces','residualcautionppa',
        'residualcautionpta', 'restrictedmovement', 'saliency_of_experience', 'scale', 'schoolreturndate', 'schoolsopen',
        'se_illnesspd', 'se_incubation', 'secondary_cases', 'seedticks', 'self_capacity', 'selfgovern', 'severity_of_illness',
        'span', 'stimulus', 'superspreaders', 'threetofour', 'threetotwo', 'timelockdownoff', 'total_population', 'track_r',
        'tracking', 'treatment_benefit', 'triggerday', 'twotoone', 'twotothree', 'undetected_proportion', 'upperstudentage',
        'vaccine_available', 'visit_frequency', 'visit_radius', 'wfh_capacity', 'zerotoone',
        # TODO: Remove from model
        'param_transmit_scale',
        # These may be useful at some point
        'asymptom_prop', 'asymptom_trace_mult', 'asymptomatic_trans', 'case_reporting_delay', 'ess_w_risk_reduction',
        'gather_location_count', 'global_transmissibility', 'illness_period', 'incubation_period', 'isolation_transmission',
        'mask_efficacy_mult', 'non_infective_time', 'reinfectionrate',
        # Parameters
        'param_vaceffdays',

    ], axis=1)
    
    cohorts = len(chunk.iloc[0].age_listOut.split(' '))
    
    if outputStaticData:
        staticData = pd.DataFrame(chunk[['age_listOut', 'atsi_listOut', 'morbid_listOut']].transpose()[0])
        staticData = SplitNetlogoList(staticData, cohorts, 0, '').transpose()
        staticData = staticData.rename(columns={'age_listOut': 'age', 'atsi_listOut': 'atsi', 'morbid_listOut': 'morbid'})
        staticData.to_csv('Output/halfDataTest/cohortLookup.csv')
        
    chunk = chunk.drop(['age_listOut', 'atsi_listOut', 'morbid_listOut'], axis=1)
    
    zero_entry = '[' + (' '.join(['0'] * cohorts)) + ']'
    chunk['infectArray_listOut'] = chunk['infectArray_listOut'].replace('0', zero_entry)
    chunk['recoverArray_listOut'] = chunk['recoverArray_listOut'].replace('0', zero_entry)
    chunk['dieArray_listOut'] = chunk['dieArray_listOut'].replace('0', zero_entry)
    
    chunk = SplitNetlogoList(chunk, cohorts, 'infectArray_listOut', 'infect_')
    chunk = SplitNetlogoList(chunk, cohorts, 'recoverArray_listOut', 'recover_')
    chunk = SplitNetlogoList(chunk, cohorts, 'dieArray_listOut', 'die_')

    for value in chunk.rand_seed.unique():
        OutputToFile(chunk[chunk.rand_seed == value], value)

def ProcessFile(filename):
    chunksize = 4 ** 8
    
    firstProcess = True
    for chunk in tqdm(pd.read_csv(filename, chunksize=chunksize, header=6), total=211):
        Process(chunk, firstProcess)
        firstProcess = False
        
ProcessFile('Output/halfDataTest/headless HalfRunTest-table.csv')        