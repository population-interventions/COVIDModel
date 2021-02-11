# -*- coding: utf-8 -*-
"""
Created on Thu Feb 11 12:11:03 2021

@author: wilsonte
"""

def MakeHeadless():
    modelFile = open('COVID SIMULS VIC JAN Vaccination Model.nlogo', 'r')
    outputFile = open('headless.nlogo', 'w')
    ignore = False
    
    while True:
        # Get next line from file
        line = modelFile.readline()
        if line == '':
            break
        line = line.rstrip()
        
        if line == 'MONITOR':
            ignore = True
        elif line == 'PLOT':
            ignore = True
        elif line == '':
            ignore = False
            
        if not ignore:
            outputFile.write(line + '\n')
    
    outputFile.close()
    modelFile.close()

MakeHeadless()
