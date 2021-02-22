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
    valueOverwrite = LowerKeys(valueOverwrite)
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
    'Global_Transmissability' : listToStr([0.32, 0.51]),
    'case_reporting_delay' : listToStr([2, 5]),
    'non_infective_Time' : listToStr([0, 2]),
    'scale_threshold' : listToStr([240, 320]),
}
topOfFile = [
    'rand_seed',
    'param_policy',
]

paramValuesTestR = {
    'rand_seed' : listToStr(random.randint(10000000, size=(200))),
    'param_policy' : listToStr([
        '"None"',
    ]),
    'Global_Transmissability' : listToStr([0.4, 0.525, 0.67]),
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
    'Global_Transmissability' : listToStr([0.36, 0.39, 0.42, 0.45, 0.48, 0.51, 0.54, 0.56, 0.59, 0.61, 0.64, 0.67, 0.7, 0.73]),
    'total_population' : '2500000000',
}

ReadModelFileAndWriteParams('GRAPHICS-WINDOW', '@#$#@#$#@', paramValuesTestR_2, topOfFile=topOfFile)
