# -*- coding: utf-8 -*-
"""
Created on Thu Feb 11 12:11:03 2021

@author: wilsonte
"""

from numpy import random

def listToStr(input):
    return " ".join(str(x) for x in input)


def MoveMatchToPos(data, match, pos):
    for i in range(len(data)):
        if data[i][0] == match:
            data[i], data[pos] = data[pos], data[i]
            return


def ToNetlogoStr(data):
    for i in data:
        if type(data[i]) is not str:
            data[i] = str(data[i]).lower()
    return data


def FindNameAndValue(file, nameLines, valueLines):
    foundName = False
    while True:
        line = file.readline().rstrip()
        if nameLines > 0:
            nameLines -= 1
            if nameLines == 0:
                foundName = line.lower()
        elif valueLines > 0:
            valueLines -= 1
            if valueLines == 0:
                return foundName, line 


def GetChooserValue(optionString, choice):
    options = optionString.split(" ")
    return options[int(choice)]


def LowerKeys(myDict):
    if not myDict:
        return False
    outdict = {}
    for k, v in myDict.items():
        outdict[k.lower()] = v
    return outdict


def ReadModelFileAndWriteParams(startPart, endPart, valueOverwrite, topOfFile=[]):
    valueOverwrite = ToNetlogoStr(LowerKeys(valueOverwrite))
    modelFile = open('COVID SIMULS VIC JAN Vaccination Model.nlogo', 'r')
    outputFile = open('paramFile.txt', 'w')
    foundPart = False
    parameters = []
    
    while True:
        # Get next line from file
        line = modelFile.readline().rstrip()
        if foundPart and line == endPart:
            break
            
        if line == startPart:
            foundPart = True
        
        if foundPart:
            if line == 'SLIDER':
                name, value = FindNameAndValue(modelFile, 5, 4)
                if value == '2.5E7':
                    value = 25000000 # >_<
                parameters.append([name, value])
            elif line == 'SWITCH':
                name, value = FindNameAndValue(modelFile, 5, 2)
                if int(value) == 0:
                    # Weird how netlogo stores switches packwards.
                    value = 'true'
                else:
                    value = 'false'
                parameters.append([name, value])
            elif line == 'INPUTBOX':
                name, value = FindNameAndValue(modelFile, 5, 1)
                parameters.append([name, value])
            elif line == 'CHOOSER':
                name, value = FindNameAndValue(modelFile, 5, 2)
                value = GetChooserValue(value, modelFile.readline().rstrip())
                parameters.append([name, value])
    
    modelFile.close()
    
    parameters.sort()
    for i in range(len(topOfFile)):
        MoveMatchToPos(parameters, topOfFile[i].lower(), i)
    
    for data in parameters:
        name, value = str(data[0]), str(data[1])
        if valueOverwrite.get(name):
            value = valueOverwrite[name]
        outputFile.write('["' + name + '" ' + value + ']\n')  
        
    
    outputFile.close()
  
defaultParams = {
    'asymptom_trace_mult' : 0.33,
    'asymptomatic_trans' : 0.5,
    'basestage' : 0,
    'calibrate_stage_switch' : 701,
    'case_reporting_delay' : 2.0,
    'complacency_bound' : 5.0,
    'end_day' : 91.0,
    'end_r_reported' : -1.0,
    'ess_w_risk_reduction' : 50.0,
    'essential_workers' : 100.0,
    'freewheel' : False,
    'gather_location_count' : 85.0,
    'illness_period' : 21.2,
    'incubation_period' : 4.7,
    'initial_cases' : 5.0,
    'initialscale' : 0,
    'isolate' : True,
    'isolation_transmission' : 0.5,
    'lockdown_off' : True,
    'mask_efficacy_mult' : 1.0,
    'mask_wearing' : 35.0,
    'maskpolicy' : True,
    'maxstage' : 4,
    'non_infective_time' : 2.0,
    'os_import_post_proportion' : 0.68,
    'os_import_proportion' : 0.0,
    'asymptom_prop' : 0.33,
    'param_trigger_loosen' : False,
    'param_vac1_tran_reduct' : 90.0,
    'param_vac2_morb_eff' : 70.0,
    'param_vac2_tran_reduct' : 75.0,
    'param_vac_uptake' : 75.0,
    'param_vaceffdays' : 21.0,
    'population' : 2500.0,
    'profile_on' : False,
    'proportion_people_avoid' : 10.0,
    'proportion_time_avoid' : 10.0,
    'age_isolation' : 0.0,
    'recovered_match_rate' : 0.042,
    'scale' : True,
    'scale_factor' : 4.0,
    'scale_threshold' : 240.0,
    'schoolsopen' : True,
    'se_illnesspd' : 4.0,
    'se_incubation' : 2.25,
    'secondary_cases' : 20.0,
    'selfgovern' : True,
    'span' : 30.0,
    'superspreaders' : 0.1,
    'symtomatic_present_day' : 6.0,
    'track_r' : True,
    'tracking' : True,
    'vaccine_available' : False,
    'visit_frequency' : 0.1428,
    'visit_radius' : 8.8,
}

  
paramValues = {
    'rand_seed' : listToStr(random.randint(10000000, size=(100))),
    'param_policy' : listToStr([
        '"AggressElim"',
        '"ModerateElim"',
        '"TightSupress"',
        '"LooseSupress"',
    ]),
    'total_population' : '25000000',
}

paramValuesTestR = {
    'rand_seed' : listToStr(random.randint(10000000, size=(100))),
    'param_policy' : listToStr([
        '"None"',
    ]),
    'total_population' : '25000000',
}
  
paramValuesBigRunTest = {
    'rand_seed' : listToStr(random.randint(10000000, size=(100))),
    'total_population' : '25000000',
    'param_policy' : listToStr([
        '"AggressElim"',
        '"ModerateElim"',
        '"TightSupress"',
        '"LooseSupress"',
    ]),
    'param_vac_uptake' : listToStr([75, 90]),
    'param_vac2_tran_reduct' : listToStr([60, 75, 90]),
    'Global_Transmissibility' : listToStr([0.32, 0.51]),
    'case_reporting_delay' : listToStr([2, 5]),
    'non_infective_Time' : listToStr([0, 2]),
    'scale_threshold' : listToStr([240, 320]),
}

topOfFile = [
    'rand_seed',
    'param_policy',
    'Global_Transmissibility',
]

paramValuesTestR = {
    'rand_seed' : listToStr(random.randint(10000000, size=(200))),
    'param_policy' : listToStr([
        '"None"',
    ]),
    'Global_Transmissibility' : listToStr([0.4, 0.525, 0.67]),
    'total_population' : '25000000',
}

paramValuesTestR_2 = {
    'rand_seed' : listToStr(random.randint(10000000, size=(2000))),
    'param_policy' : listToStr([
        '"StageCal None"',
        '"StageCal_1"',
        '"StageCal_1b"',
        '"StageCal_2"',
        '"StageCal_3"',
        '"StageCal_4"',
    ]),
    'Global_Transmissibility' : listToStr([0.36, 0.39, 0.42, 0.45, 0.48, 0.51, 0.54, 0.56, 0.59, 0.61, 0.64, 0.67, 0.7, 0.73]),
    'total_population' : '2500000000',
}

paramValuesTestR_small = {**defaultParams, **{
    'rand_seed' : listToStr(random.randint(10000000, size=(10000))),
    'param_policy' : listToStr([
        '"StageCal None"',
        #'"StageCal Isolate"',
        '"StageCal_1"',
        '"StageCal_1b"',
        '"StageCal_2"',
        '"StageCal_3"',
        '"StageCal_4"',
    ]),
    'Global_Transmissibility' : listToStr([
        0.26,
        0.335,
        0.405,
    ]),
    'calibrate_stage_switch' : 701,
    'total_population' : '2500000000',
}}

paramValuesTestR_high_track = {**defaultParams, **{
    'rand_seed' : listToStr(random.randint(10000000, size=(10000))),
    'param_policy' : listToStr([
        '"StageCal None"',
        '"StageCal Isolate"',
        #'"StageCal_1"',
        #'"StageCal_1b"',
        #'"StageCal_2"',
        #'"StageCal_3"',
        #'"StageCal_4"',
    ]),
    'Global_Transmissibility' : listToStr([
        0.26,
        0.335,
        0.405,
    ]),
    'calibrate_stage_switch' : 701,
    'total_population' : '2500000000',
}}

paramValuesTestR_stageTest = {**defaultParams, **{
    'rand_seed' : listToStr(random.randint(10000000, size=(10000))),
    'param_policy' : listToStr([
        '"StageCal Test"',
    ]),
    'Global_Transmissibility' : listToStr([
        0.26,
    ]),
    'stage_test_index' : listToStr(range(20)),
    'total_population' : '2500000000',
}}
ReadModelFileAndWriteParams('GRAPHICS-WINDOW', '@#$#@#$#@', paramValuesTestR_stageTest, topOfFile=topOfFile)
