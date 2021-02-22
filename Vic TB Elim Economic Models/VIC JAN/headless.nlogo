;; This version of the model has been speifically designed to estimate issues associated with Victoria's second wave of infections, beginning in early July
;; The intent of the model is for it to be used as a guide for considering differences in potential patterns of infection under various policy futures
;; As with any model, it's results should be interpreted with caution and placed alongside other evidence when interpreting results

extensions [ rngs profiler csv table array ]

globals [
  anxietyFactor
  InfectionChange
  infectionsToday
  infectionsToday_acc ; Accumulator for infectionsToday
  infectionsYesterday
  five
  fifteen
  twentyfive
  thirtyfive
  fortyfive
  fiftyfive
  sixtyfive
  seventyfive
  eightyfive
  ninetyfive
  InitialReserves
  AverageContacts
  AverageFinancialContacts
  ScalePhase
  Days
  CaseFatalityRate
  DeathCount
  recovercount
  recoverProportion ; Proportion of the living population that has recovered.
  casesReportedToday
  casesReportedToday_acc ; Accumulator for casesReportedToday
  Scaled_Population
  ICUBedsRequired
  scaled_Bed_Capacity
  currentInfections
  eliminationDate
  PotentialContacts
  yellowcount
  redcount
  cumulativeInfected
  scaledPopulation
  MeanR
  EWInfections
  StudentInfections
  meanDaysInfected
  lasttransday
  lastPeriod
  casesinperiod28
  casesinperiod14
  casesinperiod7
  resetDate ;; days after today that the policy is reviewed
  cashposition
  Objfunction ;; seeks to minimise the damage - totalinfection * stage * currentInfections
  decisionDate ;; a date (ticks) when policy decsions were made
  policyTriggerScale
  prior0
  prior1
  prior2
  prior3
  prior4
  prior5
  prior6
  prior7
  prior8
  prior9
  prior10
  prior11
  prior12
  prior13
  prior14
  prior15
  prior16
  prior17
  prior18
  prior19
  prior20
  prior21
  prior22
  prior23
  prior24
  prior25
  prior26
  prior27
  prior28

  fiveDayAverage
  fiveDayAverageProp
  fiveDayAvChangeAv
  fiveDayAvChangeCount

  new_case_real
  new_case_real_counter

  ;; These used to be dynamic controls with conflicting variable names.
  spatial_distance
  case_isolation
  quarantine
  contact_radius
  Track_and_Trace_Efficiency
  stage
  prev_stage ; Last stage, so that stage settting are not reset to often

  stageHasChanged
  stageToday
  stageYesterday

  houseTrackedCaseTimeTable
  houseLocationTable
  destination_patches

  houseStudentMoveCache ;; Cache of agentset that a student from household N can move to as part of school.
  houseStudentMoveCache_lastUpdate ;; When each agentset was last updated, or set to -1 to indicate it needs an update.
  houseStudentMoveCache_staleTime ;; If an agentset was updated before staleTime, regenerate it.

  PrimaryUpper
  SecondaryLower

  meanIDTime

  popDivisionTable ; Table of population cohort data
  popDivisionTable_keys ; length of table.
  populationCohortCache ; Filters for the population

  totalEndR
  totalEndCount
  endR_sum
  endR_count
  endR_mean_metric
  average_R

  ; Number of agents that are workers and essential workers respectively.
  totalWorkers
  totalEssentialWorkers
  essentialWorkerRange
  otherWorkerRange

  transmission_count
  transmission_count_metric ; For output, not dynamic change
  transmission_sum
  transmission_average

  avoidSuccess
  avoidAttempts

  draw_ppa_modifier
  draw_pta_modifier
  draw_isolationCompliance
  draw_maskWearEfficacy
  draw_borderIncursionRisk

  ; Vaccine phase and subphase, as well as internal index and data table.
  global_vaccinePhase
  global_vaccineSubPhase
  global_vaccineAvailible
  global_vaccineType
  global_vaccinePerDay
  global_incursionScale ;; Scale applied to the underlying probability, from the csv
  global_incursionArrivals ;; Number of arrivals, read from csv
  global_incursionRisk ;; Scale multiplied by the underlying probability.

  incursionsSeedID
  totalOverseasIncursions
  vaccinePhaseEndDay
  vaccinePhaseIndex
  vaccineTable
  global_vaccine_eff ;; Effectiveness of the vaccine along the three dimensions (infection rate, transmition rate, duration)

  global_schoolActive ;; Whether students ignore avoiding each other to go to school

  ;; log transform illness period variables
  Illness_PeriodVariance
  M
  BetaillnessPd
  S

  ;; log transform incubation period variables
  Incubation_PeriodVariance
  MInc
  BetaIncubationPd
  SInc

  ;; log transform compliance period variables
  Compliance_PeriodVariance
  MComp
  BetaCompliance
  SComp

  ;; file reading and draw handling
  drawNumber
  drawRandomSeed
  drawList

  ;; Data output
  cohortLengthListOfZeros
  infectArray
  recoverArray
  dieArray
  infectArray_listOut
  recoverArray_listOut
  dieArray_listOut
  age_listOut
  atsi_listOut
  morbid_listOut

  houseTotal ;; Parameter
  R_measure_time
]


__includes[
  "main.nls"
  "simul.nls"
  "setup.nls"
  "scale.nls"
  "stages.nls"
  "policy.nls"
  "trace.nls"
  "count.nls"
  "vaccine.nls"
  "debug.nls"
  "dataOut.nls"
]


patches-own [
  destination ;; indicator of whether this location is a place that people might gather
  houseIndex ;; indicator that the patch is a house.
  lastInfectionUpdate ;; Update indicator for stale simulantCount data
  infectionList ;; List of infectivities of simulants on the patch
  infectionCulprit ;; List of agents that cause infection. Only used of track_R is enabled.
  lastUtilTime ;; Last tick that the patch was occupied
  lastHouseGatherTime ;; Last tick that a house gathered here.
  houseGatherIndex ;; Last house that gathered here. -1 indicates more than one house.
]
@#$#@#$#@
GRAPHICS-WINDOW
324
74
988
739
-1
-1
10.1
1
10
1
1
1
0
1
1
1
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
220
94
284
128
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
185
142
249
176
Go
ifelse (count simuls ) = (count simuls with [ color = blue ])  [ stop ] [ Go ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
212
240
309
274
Trace_Patterns
ask n-of 50 simuls with [ color != black ] [ pen-down ]
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

BUTTON
210
280
310
314
UnTrace
ask turtles [ pen-up ]
NIL
1
T
OBSERVER
NIL
U
NIL
NIL
1

SLIDER
198
188
311
221
Population
Population
1000
2500
2500.0
500
1
NIL
HORIZONTAL

SLIDER
1445
54
1578
87
Span
Span
0
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
40
1202
240
1235
Illness_period
Illness_period
0
25
21.2
.1
1
NIL
HORIZONTAL

BUTTON
249
142
313
176
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1589
253
1768
286
superspreaders
superspreaders
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
1588
57
1770
90
Proportion_People_Avoid
Proportion_People_Avoid
0
100
90.0
.5
1
NIL
HORIZONTAL

SLIDER
1588
92
1771
125
Proportion_Time_Avoid
Proportion_Time_Avoid
0
100
90.0
.5
1
NIL
HORIZONTAL

INPUTBOX
205
332
310
393
initial_cases
5.0
1
0
Number

INPUTBOX
204
464
313
525
total_population
2.5E9
1
0
Number

SLIDER
40
1248
242
1281
Incubation_Period
Incubation_Period
0
10
4.7
.1
1
NIL
HORIZONTAL

SLIDER
1635
19
1769
52
Age_Isolation
Age_Isolation
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
1559
959
1652
992
scale
scale
0
1
-1000

SWITCH
1380
1389
1504
1422
lockdown_off
lockdown_off
0
1
-1000

SWITCH
1379
1304
1488
1337
freewheel
freewheel
1
1
-1000

TEXTBOX
1378
1257
1555
1295
Leave Freewheel to 'on' to manipulate policy on the fly
12
0.0
1

INPUTBOX
2864
474
3020
535
se_illnesspd
4.0
1
0
Number

INPUTBOX
2864
535
3020
596
se_incubation
2.25
1
0
Number

SLIDER
12
448
189
481
Global_Transmissability
Global_Transmissability
0
1
0.76
0.01
1
NIL
HORIZONTAL

SLIDER
1590
214
1768
247
Essential_Workers
Essential_Workers
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
552
872
749
905
Ess_W_Risk_Reduction
Ess_W_Risk_Reduction
0
100
50.0
1
1
NIL
HORIZONTAL

SWITCH
1449
359
1584
392
tracking
tracking
0
1
-1000

SLIDER
1445
93
1579
126
Mask_Wearing
Mask_Wearing
0
100
80.0
1
1
NIL
HORIZONTAL

SWITCH
1448
282
1583
315
schoolsOpen
schoolsOpen
1
1
-1000

SWITCH
1448
322
1582
355
MaskPolicy
MaskPolicy
0
1
-1000

SLIDER
324
909
519
942
Case_Reporting_Delay
Case_Reporting_Delay
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
1590
332
1772
365
Visit_Frequency
Visit_Frequency
0
1
0.1428
0.01
1
NIL
HORIZONTAL

SLIDER
1590
369
1773
402
Visit_Radius
Visit_Radius
0
16
1.8
1
1
NIL
HORIZONTAL

SLIDER
324
827
522
860
Asymptomatic_Trans
Asymptomatic_Trans
0
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
1590
294
1770
327
OS_Import_Proportion
OS_Import_Proportion
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
1590
178
1767
211
OS_Import_Post_Proportion
OS_Import_Post_Proportion
0
1
0.68
.01
1
NIL
HORIZONTAL

CHOOSER
1555
909
1648
954
InitialScale
InitialScale
0 1 2 3 4
0

SWITCH
1379
1344
1491
1377
SelfGovern
SelfGovern
0
1
-1000

SWITCH
1528
1328
1632
1361
Isolate
Isolate
0
1
-1000

SLIDER
39
1158
227
1191
Mask_Efficacy_Mult
Mask_Efficacy_Mult
0
3
1.0
.01
1
NIL
HORIZONTAL

SWITCH
1590
409
1775
442
Vaccine_Available
Vaccine_Available
1
1
-1000

CHOOSER
1665
1160
1804
1205
BaseStage
BaseStage
0 1 2 3 4
0

CHOOSER
1665
1215
1804
1260
MaxStage
MaxStage
0 1 2 3 4
4

SLIDER
13
15
290
48
RAND_SEED
RAND_SEED
0
10000000
3626741.0
1
1
NIL
HORIZONTAL

TEXTBOX
22
500
190
567
Vaccine rollout and vaccine used per phase set in vaccine.csv.
14
0.0
1

SLIDER
12
189
187
222
param_vac_uptake
param_vac_uptake
60
90
75.0
15
1
NIL
HORIZONTAL

SLIDER
12
232
186
265
param_vac2_morb_eff
param_vac2_morb_eff
60
80
70.0
10
1
NIL
HORIZONTAL

SLIDER
12
274
186
307
param_vac1_tran_reduct
param_vac1_tran_reduct
50
90
90.0
5
1
NIL
HORIZONTAL

SLIDER
12
314
185
347
param_vac2_tran_reduct
param_vac2_tran_reduct
50
90
75.0
5
1
NIL
HORIZONTAL

SLIDER
17
565
189
598
param_vacEffDays
param_vacEffDays
0
30
21.0
1
1
NIL
HORIZONTAL

TEXTBOX
1458
27
1582
60
Stage Policy Settings
12
0.0
1

INPUTBOX
205
397
310
457
secondary_cases
20.0
1
0
Number

CHOOSER
13
399
186
444
param_policy
param_policy
"AggressElim" "ModerateElim" "TightSupress" "LooseSupress" "None" "Stage 1" "Stage 1b" "Stage 2" "Stage 3" "Stage 4" "StageCal None" "StageCal_1" "StageCal_1b" "StageCal_2" "StageCal_3" "StageCal_4"
15

SLIDER
1555
834
1692
867
Scale_Threshold
Scale_Threshold
50
500
240.0
1
1
NIL
HORIZONTAL

SLIDER
1555
872
1693
905
Scale_Factor
Scale_Factor
2
10
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
772
1120
1160
1148
----- Everything below this line should (hopefully) be ignored. -----
11
0.0
1

TEXTBOX
37
1133
259
1152
Permanent yet straightforward variables
11
0.0
1

SLIDER
324
747
519
780
Asymptom_Prop
Asymptom_Prop
0
1
0.33
0.01
1
NIL
HORIZONTAL

SLIDER
324
787
519
820
Asymptom_Trace_Mult
Asymptom_Trace_Mult
0
1
0.33
0.01
1
NIL
HORIZONTAL

SLIDER
552
790
749
823
Gather_Location_Count
Gather_Location_Count
0
1000
85.0
1
1
NIL
HORIZONTAL

SLIDER
1589
134
1771
167
Complacency_Bound
Complacency_Bound
0
100
90.0
1
1
NIL
HORIZONTAL

BUTTON
14
102
119
136
Profile Stop
profiler:stop \nprint profiler:report
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
13
140
120
173
profile_on
profile_on
1
1
-1000

BUTTON
17
63
121
98
Profile Start
profiler:start
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1009
13
1182
46
End_Day
End_Day
-1
365
68.0
1
1
NIL
HORIZONTAL

SLIDER
549
912
747
945
Isolation_Transmission
Isolation_Transmission
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
324
870
521
903
Non_Infective_Time
Non_Infective_Time
0
4
2.0
1
1
NIL
HORIZONTAL

SWITCH
1435
739
1539
772
track_R
track_R
0
1
-1000

SLIDER
324
949
519
982
Symtomatic_Present_Day
Symtomatic_Present_Day
-1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
552
749
747
782
Recovered_Match_Rate
Recovered_Match_Rate
0
0.1
0.042
0.001
1
NIL
HORIZONTAL

SWITCH
13
357
187
390
param_trigger_loosen
param_trigger_loosen
1
1
-1000

SLIDER
1010
53
1183
86
End_R_Reported
End_R_Reported
-1
100
-1.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bed
false
15
Polygon -1 true true 45 150 45 150 90 210 240 105 195 75 45 150
Rectangle -1 true true 227 105 239 150
Rectangle -1 true true 90 195 106 250
Rectangle -1 true true 45 150 60 195
Polygon -1 true true 106 211 106 211 232 125 228 108 98 193 102 213

bog roll
true
0
Circle -1 true false 13 13 272
Circle -16777216 false false 75 75 150
Circle -16777216 true false 103 103 95
Circle -16777216 false false 59 59 182
Circle -16777216 false false 44 44 212
Circle -16777216 false false 29 29 242

bog roll2
true
0
Circle -1 true false 74 30 146
Rectangle -1 true false 75 102 220 204
Circle -1 true false 74 121 146
Circle -16777216 true false 125 75 44
Circle -16777216 false false 75 28 144

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

health care
false
15
Circle -1 true true 2 -2 302
Rectangle -2674135 true false 69 122 236 176
Rectangle -2674135 true false 127 66 181 233

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

worker1
true
15
Circle -16777216 true false 96 96 108
Circle -1 true true 108 108 85
Polygon -16777216 true false 120 180 135 195 121 245 107 246 125 190 125 190
Polygon -16777216 true false 181 182 166 197 180 247 194 248 176 192 176 192

worker2
true
15
Circle -16777216 true false 95 94 110
Circle -1 true true 108 107 85
Polygon -16777216 true false 130 197 148 197 149 258 129 258
Polygon -16777216 true false 155 258 174 258 169 191 152 196

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Test 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>ticks</metric>
    <metric>deathcount</metric>
    <metric>casesReportedToday</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="RAND_SEED">
      <value value="1234"/>
      <value value="1234"/>
      <value value="8888"/>
      <value value="5555"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;AggressElim&quot;"/>
      <value value="&quot;ModerateElim&quot;"/>
      <value value="&quot;TightSupress&quot;"/>
      <value value="&quot;LooseSupress&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Test 3" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casesReportedToday</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;ModerateElim&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_transmit_scale">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rand_seed">
      <value value="473430"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reinfectionrate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FullBaseRun" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>stage</metric>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;AggressElim&quot;"/>
      <value value="&quot;ModerateElim&quot;"/>
      <value value="&quot;TightSupress&quot;"/>
      <value value="&quot;LooseSupress&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_transmit_scale">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rand_seed">
      <value value="8077269"/>
      <value value="4904381"/>
      <value value="6601350"/>
      <value value="5207590"/>
      <value value="3905300"/>
      <value value="8998424"/>
      <value value="2584217"/>
      <value value="4715148"/>
      <value value="4308569"/>
      <value value="4970496"/>
      <value value="3106686"/>
      <value value="5837818"/>
      <value value="8565407"/>
      <value value="8366554"/>
      <value value="1052891"/>
      <value value="8709912"/>
      <value value="2827337"/>
      <value value="3165307"/>
      <value value="1352753"/>
      <value value="5973479"/>
      <value value="6533051"/>
      <value value="3234306"/>
      <value value="3440874"/>
      <value value="8222399"/>
      <value value="2722194"/>
      <value value="3678215"/>
      <value value="3025592"/>
      <value value="5312279"/>
      <value value="5816966"/>
      <value value="2132957"/>
      <value value="9445851"/>
      <value value="8314046"/>
      <value value="3189282"/>
      <value value="8212743"/>
      <value value="7970882"/>
      <value value="9956633"/>
      <value value="7915336"/>
      <value value="3282335"/>
      <value value="8445524"/>
      <value value="1155841"/>
      <value value="1526511"/>
      <value value="581331"/>
      <value value="5186173"/>
      <value value="6910650"/>
      <value value="6707668"/>
      <value value="7234376"/>
      <value value="7989959"/>
      <value value="5000604"/>
      <value value="6239071"/>
      <value value="2107629"/>
      <value value="4026982"/>
      <value value="1867186"/>
      <value value="3175434"/>
      <value value="1314998"/>
      <value value="3649980"/>
      <value value="8932522"/>
      <value value="6118345"/>
      <value value="8157868"/>
      <value value="1564949"/>
      <value value="5802474"/>
      <value value="6161611"/>
      <value value="2417674"/>
      <value value="5535290"/>
      <value value="2804222"/>
      <value value="9217263"/>
      <value value="9375516"/>
      <value value="4751164"/>
      <value value="331674"/>
      <value value="156894"/>
      <value value="7634064"/>
      <value value="2072233"/>
      <value value="6597440"/>
      <value value="5457924"/>
      <value value="6056542"/>
      <value value="5683282"/>
      <value value="7466484"/>
      <value value="3609402"/>
      <value value="8048870"/>
      <value value="4263299"/>
      <value value="1131619"/>
      <value value="6354717"/>
      <value value="8849732"/>
      <value value="4664534"/>
      <value value="492247"/>
      <value value="5419745"/>
      <value value="9647003"/>
      <value value="725234"/>
      <value value="7723046"/>
      <value value="5626241"/>
      <value value="3905759"/>
      <value value="508106"/>
      <value value="8028523"/>
      <value value="9189838"/>
      <value value="797927"/>
      <value value="9136092"/>
      <value value="4381299"/>
      <value value="3695855"/>
      <value value="8380664"/>
      <value value="6330309"/>
      <value value="1799736"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reinfectionrate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Calculator" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>average_R</metric>
    <metric>scale_threshold</metric>
    <metric>scale_factor</metric>
    <metric>global_transmissability</metric>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.3"/>
      <value value="0.24"/>
      <value value="0.375"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_transmit_scale">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rand_seed">
      <value value="2097193"/>
      <value value="6468588"/>
      <value value="1222882"/>
      <value value="8896230"/>
      <value value="1928666"/>
      <value value="4187625"/>
      <value value="3200930"/>
      <value value="8310357"/>
      <value value="7132365"/>
      <value value="218681"/>
      <value value="8823968"/>
      <value value="7392825"/>
      <value value="2220143"/>
      <value value="5482612"/>
      <value value="9223981"/>
      <value value="3466833"/>
      <value value="4013309"/>
      <value value="5995024"/>
      <value value="7034588"/>
      <value value="5658213"/>
      <value value="4529873"/>
      <value value="6950755"/>
      <value value="5935099"/>
      <value value="4676009"/>
      <value value="520981"/>
      <value value="1549421"/>
      <value value="1706056"/>
      <value value="6302125"/>
      <value value="7504158"/>
      <value value="8046029"/>
      <value value="4735977"/>
      <value value="3433406"/>
      <value value="7604756"/>
      <value value="116293"/>
      <value value="3180704"/>
      <value value="2788207"/>
      <value value="4979179"/>
      <value value="9679793"/>
      <value value="2149533"/>
      <value value="1061225"/>
      <value value="4125257"/>
      <value value="4025610"/>
      <value value="1958634"/>
      <value value="4367335"/>
      <value value="8000634"/>
      <value value="104360"/>
      <value value="284650"/>
      <value value="582078"/>
      <value value="2865610"/>
      <value value="4515524"/>
      <value value="6702544"/>
      <value value="1217107"/>
      <value value="5755633"/>
      <value value="7749231"/>
      <value value="2498840"/>
      <value value="1348144"/>
      <value value="3704932"/>
      <value value="3226515"/>
      <value value="2237370"/>
      <value value="491779"/>
      <value value="9610421"/>
      <value value="489966"/>
      <value value="351494"/>
      <value value="2193732"/>
      <value value="2278188"/>
      <value value="2396668"/>
      <value value="2244826"/>
      <value value="8109679"/>
      <value value="2608764"/>
      <value value="2290683"/>
      <value value="3301852"/>
      <value value="1881990"/>
      <value value="3599456"/>
      <value value="4718393"/>
      <value value="378045"/>
      <value value="5627179"/>
      <value value="9108973"/>
      <value value="8180118"/>
      <value value="3031230"/>
      <value value="2492088"/>
      <value value="4317631"/>
      <value value="2217304"/>
      <value value="6872793"/>
      <value value="8410978"/>
      <value value="6169288"/>
      <value value="968524"/>
      <value value="6731924"/>
      <value value="7425433"/>
      <value value="4839445"/>
      <value value="4033500"/>
      <value value="8043494"/>
      <value value="6152337"/>
      <value value="8044477"/>
      <value value="280690"/>
      <value value="4104369"/>
      <value value="2908179"/>
      <value value="3122616"/>
      <value value="2595"/>
      <value value="9957437"/>
      <value value="980521"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reinfectionrate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="260"/>
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="arrayTest" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>days</metric>
    <metric>stage</metric>
    <metric>infectArray_listOut</metric>
    <metric>recoverArray_listOut</metric>
    <metric>dieArray_listOut</metric>
    <metric>age_listOut</metric>
    <metric>atsi_listOut</metric>
    <metric>morbid_listOut</metric>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation_Transmission">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RAND_SEED">
      <value value="922705"/>
      <value value="56411"/>
      <value value="265412"/>
      <value value="568941"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GoldStandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gather_Location_Count">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency_Bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_R">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;TightSupress&quot;"/>
      <value value="&quot;ModerateElim&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy_Mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaxStage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Non_Infective_Time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vacEffDays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Available">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scale_Threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="0.32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="End_Day">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptom_Trace_Mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Quarantine_Spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptom_Prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scale_Factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsOpen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_transmit_scale">
      <value value="1.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HalfRunTest" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>days</metric>
    <metric>stage</metric>
    <metric>scalephase</metric>
    <metric>cumulativeInfected</metric>
    <metric>casesReportedToday</metric>
    <metric>Deathcount</metric>
    <metric>totalOverseasIncursions</metric>
    <metric>infectArray_listOut</metric>
    <metric>recoverArray_listOut</metric>
    <metric>dieArray_listOut</metric>
    <metric>age_listOut</metric>
    <metric>atsi_listOut</metric>
    <metric>morbid_listOut</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="5123399"/>
      <value value="7126990"/>
      <value value="3884295"/>
      <value value="7314860"/>
      <value value="1968051"/>
      <value value="3990864"/>
      <value value="3286330"/>
      <value value="4693122"/>
      <value value="6022217"/>
      <value value="1135583"/>
      <value value="4497466"/>
      <value value="9751593"/>
      <value value="8733168"/>
      <value value="1061485"/>
      <value value="155217"/>
      <value value="8800719"/>
      <value value="1909322"/>
      <value value="4246717"/>
      <value value="4330431"/>
      <value value="9953674"/>
      <value value="2250768"/>
      <value value="1130843"/>
      <value value="5164721"/>
      <value value="2809261"/>
      <value value="7543759"/>
      <value value="9875600"/>
      <value value="3542488"/>
      <value value="107189"/>
      <value value="6266114"/>
      <value value="4470257"/>
      <value value="89571"/>
      <value value="7194362"/>
      <value value="1903676"/>
      <value value="6978999"/>
      <value value="8707861"/>
      <value value="9322170"/>
      <value value="894109"/>
      <value value="369437"/>
      <value value="1822787"/>
      <value value="4416615"/>
      <value value="1933897"/>
      <value value="6354173"/>
      <value value="8195958"/>
      <value value="9595598"/>
      <value value="4644972"/>
      <value value="4078550"/>
      <value value="8232721"/>
      <value value="2464410"/>
      <value value="9138243"/>
      <value value="5895400"/>
      <value value="3093354"/>
      <value value="8705972"/>
      <value value="5890681"/>
      <value value="9151904"/>
      <value value="7220199"/>
      <value value="6510324"/>
      <value value="1677310"/>
      <value value="463935"/>
      <value value="3584581"/>
      <value value="1287424"/>
      <value value="8455914"/>
      <value value="3372067"/>
      <value value="1672187"/>
      <value value="1483413"/>
      <value value="3646903"/>
      <value value="3288807"/>
      <value value="1301006"/>
      <value value="202382"/>
      <value value="114974"/>
      <value value="2581159"/>
      <value value="466766"/>
      <value value="8713811"/>
      <value value="7195020"/>
      <value value="4640659"/>
      <value value="458936"/>
      <value value="9011227"/>
      <value value="5528864"/>
      <value value="8551952"/>
      <value value="4065633"/>
      <value value="2555994"/>
      <value value="5983028"/>
      <value value="3322088"/>
      <value value="2644197"/>
      <value value="6155250"/>
      <value value="274953"/>
      <value value="4294616"/>
      <value value="9158019"/>
      <value value="3547392"/>
      <value value="1898832"/>
      <value value="7931595"/>
      <value value="956950"/>
      <value value="6658796"/>
      <value value="3169217"/>
      <value value="1880710"/>
      <value value="5430881"/>
      <value value="1548489"/>
      <value value="3882852"/>
      <value value="5250366"/>
      <value value="7870552"/>
      <value value="5016193"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.32"/>
      <value value="0.51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="0"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;AggressElim&quot;"/>
      <value value="&quot;ModerateElim&quot;"/>
      <value value="&quot;TightSupress&quot;"/>
      <value value="&quot;LooseSupress&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_transmit_scale">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="60"/>
      <value value="75"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reinfectionrate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
      <value value="320"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Test 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="332935"/>
      <value value="8268277"/>
      <value value="3477847"/>
      <value value="7914662"/>
      <value value="105023"/>
      <value value="3075088"/>
      <value value="3583990"/>
      <value value="4050335"/>
      <value value="4846990"/>
      <value value="3400162"/>
      <value value="7887108"/>
      <value value="7682084"/>
      <value value="8225191"/>
      <value value="1189912"/>
      <value value="7766489"/>
      <value value="5474821"/>
      <value value="5452003"/>
      <value value="4585116"/>
      <value value="7447863"/>
      <value value="7691857"/>
      <value value="283845"/>
      <value value="5603314"/>
      <value value="8304754"/>
      <value value="8525843"/>
      <value value="1774885"/>
      <value value="6836620"/>
      <value value="8884727"/>
      <value value="3015789"/>
      <value value="5400455"/>
      <value value="6781814"/>
      <value value="2070476"/>
      <value value="8078547"/>
      <value value="3214528"/>
      <value value="3510276"/>
      <value value="7237450"/>
      <value value="4681331"/>
      <value value="7644749"/>
      <value value="7170916"/>
      <value value="1678077"/>
      <value value="8830670"/>
      <value value="5464849"/>
      <value value="3621096"/>
      <value value="5175841"/>
      <value value="6950922"/>
      <value value="5261315"/>
      <value value="4738354"/>
      <value value="9193080"/>
      <value value="3378977"/>
      <value value="6244933"/>
      <value value="9977210"/>
      <value value="3472651"/>
      <value value="4598183"/>
      <value value="1714447"/>
      <value value="4922099"/>
      <value value="6141461"/>
      <value value="4409494"/>
      <value value="4191011"/>
      <value value="5153466"/>
      <value value="5503152"/>
      <value value="3026085"/>
      <value value="7438306"/>
      <value value="7854383"/>
      <value value="4411026"/>
      <value value="3538562"/>
      <value value="2129597"/>
      <value value="7131135"/>
      <value value="2982508"/>
      <value value="9657825"/>
      <value value="9474753"/>
      <value value="1536669"/>
      <value value="7486498"/>
      <value value="2351838"/>
      <value value="817267"/>
      <value value="1447658"/>
      <value value="1434621"/>
      <value value="7532932"/>
      <value value="8187375"/>
      <value value="2349492"/>
      <value value="8591210"/>
      <value value="2809024"/>
      <value value="9040916"/>
      <value value="5138628"/>
      <value value="4317519"/>
      <value value="9575113"/>
      <value value="8871081"/>
      <value value="6134025"/>
      <value value="19856"/>
      <value value="8816292"/>
      <value value="7476499"/>
      <value value="9865436"/>
      <value value="4149808"/>
      <value value="873340"/>
      <value value="3418172"/>
      <value value="2001070"/>
      <value value="8320110"/>
      <value value="3443908"/>
      <value value="9614862"/>
      <value value="7974462"/>
      <value value="3536523"/>
      <value value="9432050"/>
      <value value="4053781"/>
      <value value="3068037"/>
      <value value="8784033"/>
      <value value="7809752"/>
      <value value="4338149"/>
      <value value="4601052"/>
      <value value="6121692"/>
      <value value="4881789"/>
      <value value="8422974"/>
      <value value="9551735"/>
      <value value="1752295"/>
      <value value="5099276"/>
      <value value="5266987"/>
      <value value="2749433"/>
      <value value="5949428"/>
      <value value="1494635"/>
      <value value="805152"/>
      <value value="1056635"/>
      <value value="3278678"/>
      <value value="6709248"/>
      <value value="9088393"/>
      <value value="3226574"/>
      <value value="5733432"/>
      <value value="9409267"/>
      <value value="7971358"/>
      <value value="4145403"/>
      <value value="942699"/>
      <value value="7806405"/>
      <value value="6610270"/>
      <value value="5545337"/>
      <value value="5708426"/>
      <value value="559178"/>
      <value value="2149162"/>
      <value value="5700817"/>
      <value value="2622521"/>
      <value value="9375316"/>
      <value value="7835541"/>
      <value value="6362851"/>
      <value value="7749323"/>
      <value value="3705310"/>
      <value value="4748657"/>
      <value value="9352934"/>
      <value value="4123081"/>
      <value value="8103910"/>
      <value value="7293964"/>
      <value value="9408345"/>
      <value value="5611110"/>
      <value value="8897269"/>
      <value value="2812191"/>
      <value value="5422216"/>
      <value value="1421656"/>
      <value value="5825411"/>
      <value value="5640511"/>
      <value value="5288975"/>
      <value value="8538585"/>
      <value value="2455194"/>
      <value value="4843504"/>
      <value value="5851090"/>
      <value value="309909"/>
      <value value="5446102"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Test 3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="4532922"/>
      <value value="389429"/>
      <value value="8093429"/>
      <value value="5227773"/>
      <value value="2352130"/>
      <value value="9878044"/>
      <value value="9618029"/>
      <value value="8940716"/>
      <value value="3899826"/>
      <value value="2376437"/>
      <value value="2780450"/>
      <value value="1229052"/>
      <value value="3001234"/>
      <value value="7243527"/>
      <value value="129492"/>
      <value value="7296347"/>
      <value value="5417852"/>
      <value value="1913316"/>
      <value value="8147224"/>
      <value value="9423783"/>
      <value value="2571082"/>
      <value value="2994581"/>
      <value value="2326888"/>
      <value value="5140496"/>
      <value value="6778468"/>
      <value value="6426311"/>
      <value value="158393"/>
      <value value="1371716"/>
      <value value="9553115"/>
      <value value="8978016"/>
      <value value="3415450"/>
      <value value="3925821"/>
      <value value="3773463"/>
      <value value="9378819"/>
      <value value="6869206"/>
      <value value="3152229"/>
      <value value="6208321"/>
      <value value="4632675"/>
      <value value="5094595"/>
      <value value="3925990"/>
      <value value="5875417"/>
      <value value="2947983"/>
      <value value="9301174"/>
      <value value="6431169"/>
      <value value="4940898"/>
      <value value="9854048"/>
      <value value="1360641"/>
      <value value="3847986"/>
      <value value="9759754"/>
      <value value="4582339"/>
      <value value="8017252"/>
      <value value="2089239"/>
      <value value="6434023"/>
      <value value="122881"/>
      <value value="7392851"/>
      <value value="9415115"/>
      <value value="7227705"/>
      <value value="2686032"/>
      <value value="4172527"/>
      <value value="3007617"/>
      <value value="8375124"/>
      <value value="8681798"/>
      <value value="809073"/>
      <value value="709938"/>
      <value value="2151402"/>
      <value value="3662513"/>
      <value value="3709117"/>
      <value value="9081525"/>
      <value value="1916029"/>
      <value value="112246"/>
      <value value="9428749"/>
      <value value="4028772"/>
      <value value="7115253"/>
      <value value="9069814"/>
      <value value="7070254"/>
      <value value="2616899"/>
      <value value="3072272"/>
      <value value="3524841"/>
      <value value="9629008"/>
      <value value="5537416"/>
      <value value="5018549"/>
      <value value="8350900"/>
      <value value="4338976"/>
      <value value="56229"/>
      <value value="2975747"/>
      <value value="5951307"/>
      <value value="503362"/>
      <value value="5433834"/>
      <value value="8167707"/>
      <value value="5817706"/>
      <value value="9083466"/>
      <value value="712355"/>
      <value value="3783515"/>
      <value value="5304344"/>
      <value value="4535869"/>
      <value value="4488568"/>
      <value value="3952078"/>
      <value value="315346"/>
      <value value="3071646"/>
      <value value="6280815"/>
      <value value="4353530"/>
      <value value="8553600"/>
      <value value="7095707"/>
      <value value="4350640"/>
      <value value="2090233"/>
      <value value="3703995"/>
      <value value="1006181"/>
      <value value="231022"/>
      <value value="6865082"/>
      <value value="7320961"/>
      <value value="8438292"/>
      <value value="4817900"/>
      <value value="1044845"/>
      <value value="1502506"/>
      <value value="9409916"/>
      <value value="3600061"/>
      <value value="3860395"/>
      <value value="9520803"/>
      <value value="696553"/>
      <value value="3999628"/>
      <value value="1729245"/>
      <value value="3115213"/>
      <value value="4529512"/>
      <value value="3761375"/>
      <value value="9526180"/>
      <value value="7228781"/>
      <value value="3389006"/>
      <value value="1639249"/>
      <value value="8594440"/>
      <value value="5476219"/>
      <value value="8493439"/>
      <value value="4231239"/>
      <value value="7376082"/>
      <value value="2555780"/>
      <value value="4973557"/>
      <value value="667273"/>
      <value value="9858232"/>
      <value value="5813522"/>
      <value value="5887876"/>
      <value value="657971"/>
      <value value="2735867"/>
      <value value="1455147"/>
      <value value="9276591"/>
      <value value="9745585"/>
      <value value="712718"/>
      <value value="4326725"/>
      <value value="5601010"/>
      <value value="9039781"/>
      <value value="9310937"/>
      <value value="6697830"/>
      <value value="355839"/>
      <value value="9270388"/>
      <value value="448082"/>
      <value value="331148"/>
      <value value="1015817"/>
      <value value="6228130"/>
      <value value="6200965"/>
      <value value="4319174"/>
      <value value="9693092"/>
      <value value="9437998"/>
      <value value="3375612"/>
      <value value="1202570"/>
      <value value="5802073"/>
      <value value="313600"/>
      <value value="4616646"/>
      <value value="7223408"/>
      <value value="7948171"/>
      <value value="1030218"/>
      <value value="5004666"/>
      <value value="5137319"/>
      <value value="5132849"/>
      <value value="6319501"/>
      <value value="2088191"/>
      <value value="2091972"/>
      <value value="5546312"/>
      <value value="3831289"/>
      <value value="6049818"/>
      <value value="4005281"/>
      <value value="388310"/>
      <value value="8503084"/>
      <value value="2125161"/>
      <value value="2851814"/>
      <value value="4878706"/>
      <value value="4460873"/>
      <value value="3141814"/>
      <value value="1660366"/>
      <value value="7586178"/>
      <value value="715301"/>
      <value value="1613570"/>
      <value value="9230702"/>
      <value value="9329086"/>
      <value value="2218538"/>
      <value value="9981225"/>
      <value value="4599226"/>
      <value value="8023765"/>
      <value value="7860680"/>
      <value value="8656413"/>
      <value value="3976570"/>
      <value value="2690936"/>
      <value value="906136"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.4"/>
      <value value="0.521"/>
      <value value="0.637"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Test 4" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <metric>days</metric>
    <metric>totalEndCount</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="6135175"/>
      <value value="6031826"/>
      <value value="2389073"/>
      <value value="3681996"/>
      <value value="2907451"/>
      <value value="2882997"/>
      <value value="2405101"/>
      <value value="397453"/>
      <value value="1143688"/>
      <value value="9069808"/>
      <value value="937848"/>
      <value value="6295146"/>
      <value value="7832952"/>
      <value value="4515653"/>
      <value value="8008024"/>
      <value value="9987748"/>
      <value value="7980488"/>
      <value value="4169652"/>
      <value value="2972561"/>
      <value value="7193997"/>
      <value value="1121250"/>
      <value value="8702348"/>
      <value value="3140584"/>
      <value value="815091"/>
      <value value="6439106"/>
      <value value="3157090"/>
      <value value="9394964"/>
      <value value="1958871"/>
      <value value="8931670"/>
      <value value="4791866"/>
      <value value="4103911"/>
      <value value="4055770"/>
      <value value="1104522"/>
      <value value="9619874"/>
      <value value="632738"/>
      <value value="8037807"/>
      <value value="2456651"/>
      <value value="8277864"/>
      <value value="1367030"/>
      <value value="6987909"/>
      <value value="9452019"/>
      <value value="5286193"/>
      <value value="2901952"/>
      <value value="723338"/>
      <value value="180323"/>
      <value value="9812300"/>
      <value value="948385"/>
      <value value="7582445"/>
      <value value="9596559"/>
      <value value="6576001"/>
      <value value="5604790"/>
      <value value="756162"/>
      <value value="3609117"/>
      <value value="2086149"/>
      <value value="4388172"/>
      <value value="7267954"/>
      <value value="2623116"/>
      <value value="1990388"/>
      <value value="6723465"/>
      <value value="7758650"/>
      <value value="9269889"/>
      <value value="5571076"/>
      <value value="7186638"/>
      <value value="1875362"/>
      <value value="9821236"/>
      <value value="1464134"/>
      <value value="8938116"/>
      <value value="4529554"/>
      <value value="1559175"/>
      <value value="1913331"/>
      <value value="3265692"/>
      <value value="9677363"/>
      <value value="9589935"/>
      <value value="5219147"/>
      <value value="4939447"/>
      <value value="103599"/>
      <value value="7460021"/>
      <value value="3621169"/>
      <value value="3667417"/>
      <value value="603779"/>
      <value value="6029664"/>
      <value value="317318"/>
      <value value="1986263"/>
      <value value="9836521"/>
      <value value="9479501"/>
      <value value="5874760"/>
      <value value="4221165"/>
      <value value="2342068"/>
      <value value="1378812"/>
      <value value="5931458"/>
      <value value="6457150"/>
      <value value="7073447"/>
      <value value="92167"/>
      <value value="4604279"/>
      <value value="6417097"/>
      <value value="678577"/>
      <value value="6098238"/>
      <value value="4665914"/>
      <value value="4335514"/>
      <value value="9472173"/>
      <value value="298468"/>
      <value value="4486539"/>
      <value value="3985217"/>
      <value value="6193879"/>
      <value value="2806858"/>
      <value value="1471419"/>
      <value value="9602541"/>
      <value value="257047"/>
      <value value="9242901"/>
      <value value="7887371"/>
      <value value="4879114"/>
      <value value="2768887"/>
      <value value="1776564"/>
      <value value="8621732"/>
      <value value="2843320"/>
      <value value="5782011"/>
      <value value="7943157"/>
      <value value="372511"/>
      <value value="8656795"/>
      <value value="34723"/>
      <value value="3317519"/>
      <value value="702959"/>
      <value value="6583602"/>
      <value value="4660188"/>
      <value value="5331123"/>
      <value value="7375259"/>
      <value value="9466306"/>
      <value value="1590443"/>
      <value value="529620"/>
      <value value="4679263"/>
      <value value="7124643"/>
      <value value="4270098"/>
      <value value="7123176"/>
      <value value="3434943"/>
      <value value="7247147"/>
      <value value="3711578"/>
      <value value="8529752"/>
      <value value="308476"/>
      <value value="1881394"/>
      <value value="1910557"/>
      <value value="9234817"/>
      <value value="5623432"/>
      <value value="5778323"/>
      <value value="5683817"/>
      <value value="5967919"/>
      <value value="6829286"/>
      <value value="1789235"/>
      <value value="3535686"/>
      <value value="5797740"/>
      <value value="8399199"/>
      <value value="3176628"/>
      <value value="8442425"/>
      <value value="3620964"/>
      <value value="7085078"/>
      <value value="579046"/>
      <value value="4243574"/>
      <value value="3480858"/>
      <value value="8742124"/>
      <value value="3799956"/>
      <value value="5129985"/>
      <value value="1600986"/>
      <value value="9128870"/>
      <value value="7935492"/>
      <value value="4832412"/>
      <value value="7389216"/>
      <value value="6992959"/>
      <value value="8646343"/>
      <value value="9794810"/>
      <value value="2816293"/>
      <value value="2291622"/>
      <value value="2576376"/>
      <value value="1126878"/>
      <value value="6229567"/>
      <value value="1572278"/>
      <value value="8891660"/>
      <value value="6679866"/>
      <value value="3971004"/>
      <value value="8071575"/>
      <value value="3105102"/>
      <value value="9817263"/>
      <value value="5739740"/>
      <value value="8434039"/>
      <value value="8067155"/>
      <value value="9740335"/>
      <value value="9659711"/>
      <value value="1248048"/>
      <value value="102374"/>
      <value value="8288986"/>
      <value value="8513146"/>
      <value value="8642152"/>
      <value value="3480700"/>
      <value value="5485929"/>
      <value value="2213410"/>
      <value value="9859838"/>
      <value value="3552011"/>
      <value value="2276741"/>
      <value value="8154626"/>
      <value value="8976447"/>
      <value value="7165309"/>
      <value value="4272752"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_r_reported">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.36"/>
      <value value="0.48"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Test 5" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <metric>days</metric>
    <metric>totalEndCount</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="302579"/>
      <value value="592294"/>
      <value value="9450829"/>
      <value value="3914836"/>
      <value value="6784531"/>
      <value value="989565"/>
      <value value="7992926"/>
      <value value="8558914"/>
      <value value="1850469"/>
      <value value="1432261"/>
      <value value="569464"/>
      <value value="6190674"/>
      <value value="3145931"/>
      <value value="9687357"/>
      <value value="1242965"/>
      <value value="5399811"/>
      <value value="6948149"/>
      <value value="143151"/>
      <value value="8484242"/>
      <value value="1559586"/>
      <value value="8710443"/>
      <value value="3199666"/>
      <value value="4699166"/>
      <value value="7835696"/>
      <value value="656602"/>
      <value value="4533079"/>
      <value value="8200627"/>
      <value value="3401912"/>
      <value value="1433519"/>
      <value value="3532148"/>
      <value value="3193718"/>
      <value value="9867250"/>
      <value value="8340487"/>
      <value value="1835295"/>
      <value value="8348681"/>
      <value value="9839037"/>
      <value value="2948492"/>
      <value value="8827776"/>
      <value value="1973501"/>
      <value value="4521315"/>
      <value value="414177"/>
      <value value="235831"/>
      <value value="370875"/>
      <value value="3031812"/>
      <value value="9956913"/>
      <value value="749681"/>
      <value value="2944670"/>
      <value value="5818131"/>
      <value value="9707771"/>
      <value value="9721945"/>
      <value value="4227938"/>
      <value value="4339116"/>
      <value value="4299620"/>
      <value value="3542257"/>
      <value value="838811"/>
      <value value="4883472"/>
      <value value="1269899"/>
      <value value="3667333"/>
      <value value="6502363"/>
      <value value="9229043"/>
      <value value="4425985"/>
      <value value="4679279"/>
      <value value="8640363"/>
      <value value="7609120"/>
      <value value="1845430"/>
      <value value="5071998"/>
      <value value="2477629"/>
      <value value="2289015"/>
      <value value="630539"/>
      <value value="700202"/>
      <value value="970373"/>
      <value value="8900832"/>
      <value value="6927615"/>
      <value value="1704444"/>
      <value value="6182689"/>
      <value value="8203382"/>
      <value value="268694"/>
      <value value="7809038"/>
      <value value="9112062"/>
      <value value="1521116"/>
      <value value="7810811"/>
      <value value="9358020"/>
      <value value="4917903"/>
      <value value="4639318"/>
      <value value="652453"/>
      <value value="2192084"/>
      <value value="9405093"/>
      <value value="1180107"/>
      <value value="1040028"/>
      <value value="7071721"/>
      <value value="454622"/>
      <value value="9849979"/>
      <value value="7325240"/>
      <value value="2979677"/>
      <value value="6907601"/>
      <value value="4399363"/>
      <value value="3972698"/>
      <value value="6098294"/>
      <value value="3951656"/>
      <value value="5246868"/>
      <value value="6250077"/>
      <value value="1385800"/>
      <value value="5285190"/>
      <value value="3476170"/>
      <value value="1010908"/>
      <value value="4902259"/>
      <value value="1303023"/>
      <value value="4877811"/>
      <value value="2956289"/>
      <value value="7332107"/>
      <value value="6534580"/>
      <value value="4542655"/>
      <value value="7074115"/>
      <value value="8126500"/>
      <value value="6048883"/>
      <value value="6578181"/>
      <value value="897052"/>
      <value value="1984538"/>
      <value value="3491776"/>
      <value value="959878"/>
      <value value="6662592"/>
      <value value="1152839"/>
      <value value="2249741"/>
      <value value="1723608"/>
      <value value="7491430"/>
      <value value="9129996"/>
      <value value="3895680"/>
      <value value="4808246"/>
      <value value="3411679"/>
      <value value="3460665"/>
      <value value="6396664"/>
      <value value="1402867"/>
      <value value="1733954"/>
      <value value="9820187"/>
      <value value="5206965"/>
      <value value="9808711"/>
      <value value="2011471"/>
      <value value="2169805"/>
      <value value="2790497"/>
      <value value="7710906"/>
      <value value="379472"/>
      <value value="800213"/>
      <value value="1989144"/>
      <value value="7773072"/>
      <value value="3834013"/>
      <value value="7200025"/>
      <value value="3691156"/>
      <value value="8188837"/>
      <value value="3353585"/>
      <value value="1937786"/>
      <value value="8486869"/>
      <value value="2537449"/>
      <value value="6878288"/>
      <value value="6352503"/>
      <value value="3128907"/>
      <value value="5513098"/>
      <value value="1920573"/>
      <value value="5635619"/>
      <value value="8249656"/>
      <value value="5548181"/>
      <value value="4935042"/>
      <value value="3004300"/>
      <value value="4325486"/>
      <value value="5147692"/>
      <value value="7083357"/>
      <value value="2045911"/>
      <value value="2307775"/>
      <value value="210636"/>
      <value value="3795848"/>
      <value value="2582417"/>
      <value value="2465092"/>
      <value value="227070"/>
      <value value="147903"/>
      <value value="685902"/>
      <value value="5486676"/>
      <value value="6372644"/>
      <value value="992179"/>
      <value value="6881708"/>
      <value value="2447543"/>
      <value value="7156394"/>
      <value value="4343905"/>
      <value value="2350325"/>
      <value value="1961235"/>
      <value value="1279818"/>
      <value value="9027131"/>
      <value value="9503797"/>
      <value value="3024809"/>
      <value value="4618965"/>
      <value value="8812869"/>
      <value value="9169785"/>
      <value value="2613386"/>
      <value value="3199427"/>
      <value value="3751573"/>
      <value value="3869100"/>
      <value value="5358304"/>
      <value value="230615"/>
      <value value="9875296"/>
      <value value="7887910"/>
      <value value="7012013"/>
      <value value="3206086"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assignappess">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="available_resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bed_capacity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_adjustment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_r_reported">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ewappuptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feartrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.36"/>
      <value value="0.48"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goldstandard">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_beds_in_australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="household_attack">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_beds_in_australia">
      <value value="7400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="icu_required">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incursionrate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lowerstudentage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_individual_income">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsiderisk">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app_uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productionrate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine_spaces">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionppa">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residualcautionpta">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restrictedmovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_of_illness">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timelockdownoff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment_benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="undetected_proportion">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upperstudentage">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wfh_capacity">
      <value value="29.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R Test 6" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <metric>days</metric>
    <metric>totalEndCount</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="8563913"/>
      <value value="6896081"/>
      <value value="8716250"/>
      <value value="1658925"/>
      <value value="8654084"/>
      <value value="7393609"/>
      <value value="9381344"/>
      <value value="4166503"/>
      <value value="9076277"/>
      <value value="5962964"/>
      <value value="7551446"/>
      <value value="5019062"/>
      <value value="1273485"/>
      <value value="1221929"/>
      <value value="2253595"/>
      <value value="4496908"/>
      <value value="7619605"/>
      <value value="1191248"/>
      <value value="9216649"/>
      <value value="1369885"/>
      <value value="7788712"/>
      <value value="6304168"/>
      <value value="176547"/>
      <value value="5291681"/>
      <value value="434216"/>
      <value value="9852827"/>
      <value value="1774684"/>
      <value value="671169"/>
      <value value="1903216"/>
      <value value="5474805"/>
      <value value="5716310"/>
      <value value="8568364"/>
      <value value="3025053"/>
      <value value="7733996"/>
      <value value="2410303"/>
      <value value="3885689"/>
      <value value="9920582"/>
      <value value="2756468"/>
      <value value="9718357"/>
      <value value="816329"/>
      <value value="410162"/>
      <value value="5527966"/>
      <value value="2077027"/>
      <value value="6438798"/>
      <value value="5295616"/>
      <value value="7074381"/>
      <value value="6084160"/>
      <value value="5550393"/>
      <value value="2175221"/>
      <value value="4845149"/>
      <value value="8373644"/>
      <value value="3697281"/>
      <value value="2546131"/>
      <value value="8949630"/>
      <value value="3935774"/>
      <value value="3570422"/>
      <value value="2130541"/>
      <value value="7944259"/>
      <value value="1998246"/>
      <value value="2067692"/>
      <value value="3582592"/>
      <value value="5806468"/>
      <value value="5862888"/>
      <value value="8517383"/>
      <value value="9677374"/>
      <value value="1940396"/>
      <value value="4883575"/>
      <value value="1125619"/>
      <value value="3468620"/>
      <value value="346306"/>
      <value value="8232219"/>
      <value value="7527415"/>
      <value value="4728619"/>
      <value value="3014992"/>
      <value value="6590573"/>
      <value value="57224"/>
      <value value="4165770"/>
      <value value="1813686"/>
      <value value="5890220"/>
      <value value="7326997"/>
      <value value="6263591"/>
      <value value="3759550"/>
      <value value="2145363"/>
      <value value="9764416"/>
      <value value="3456748"/>
      <value value="4578601"/>
      <value value="1992488"/>
      <value value="4297778"/>
      <value value="674374"/>
      <value value="3108278"/>
      <value value="4663499"/>
      <value value="2051238"/>
      <value value="2054032"/>
      <value value="9382671"/>
      <value value="6406051"/>
      <value value="8370371"/>
      <value value="363530"/>
      <value value="422305"/>
      <value value="2072156"/>
      <value value="5759048"/>
      <value value="3771331"/>
      <value value="9632598"/>
      <value value="3490102"/>
      <value value="864202"/>
      <value value="1428404"/>
      <value value="4072490"/>
      <value value="8768881"/>
      <value value="9336010"/>
      <value value="5180397"/>
      <value value="4602021"/>
      <value value="6786942"/>
      <value value="758893"/>
      <value value="801352"/>
      <value value="4517400"/>
      <value value="8887614"/>
      <value value="4711872"/>
      <value value="6626431"/>
      <value value="3104745"/>
      <value value="5782726"/>
      <value value="7783986"/>
      <value value="8241791"/>
      <value value="7964588"/>
      <value value="6140779"/>
      <value value="3036013"/>
      <value value="3091196"/>
      <value value="5828723"/>
      <value value="4875104"/>
      <value value="6859490"/>
      <value value="850548"/>
      <value value="8656630"/>
      <value value="188520"/>
      <value value="7735064"/>
      <value value="6825451"/>
      <value value="901356"/>
      <value value="396370"/>
      <value value="5102901"/>
      <value value="5163986"/>
      <value value="8842354"/>
      <value value="6120839"/>
      <value value="5314122"/>
      <value value="6028398"/>
      <value value="9356948"/>
      <value value="1947169"/>
      <value value="8653404"/>
      <value value="4231004"/>
      <value value="1761979"/>
      <value value="1679089"/>
      <value value="5383870"/>
      <value value="2130504"/>
      <value value="6123973"/>
      <value value="763399"/>
      <value value="2749683"/>
      <value value="4810649"/>
      <value value="841673"/>
      <value value="823366"/>
      <value value="5345757"/>
      <value value="5243304"/>
      <value value="3132595"/>
      <value value="3980837"/>
      <value value="964068"/>
      <value value="7597837"/>
      <value value="9042112"/>
      <value value="6474595"/>
      <value value="1605999"/>
      <value value="7914647"/>
      <value value="2320165"/>
      <value value="8942886"/>
      <value value="2405567"/>
      <value value="9427839"/>
      <value value="2599922"/>
      <value value="2813896"/>
      <value value="2436690"/>
      <value value="946951"/>
      <value value="6250263"/>
      <value value="4063839"/>
      <value value="4999281"/>
      <value value="9516212"/>
      <value value="4388825"/>
      <value value="5111180"/>
      <value value="881856"/>
      <value value="2941710"/>
      <value value="5274810"/>
      <value value="2191147"/>
      <value value="5279744"/>
      <value value="6818620"/>
      <value value="4779642"/>
      <value value="5934851"/>
      <value value="8237963"/>
      <value value="8676343"/>
      <value value="7886200"/>
      <value value="6143099"/>
      <value value="7887499"/>
      <value value="5986512"/>
      <value value="1887681"/>
      <value value="5588224"/>
      <value value="2519155"/>
      <value value="2499893"/>
      <value value="8516189"/>
      <value value="6306344"/>
      <value value="9754863"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_r_reported">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.4"/>
      <value value="0.525"/>
      <value value="0.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="8.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Big R Test" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <metric>days</metric>
    <metric>totalEndCount</metric>
    <metric>scalephase</metric>
    <metric>cumulativeInfected</metric>
    <metric>infectionsToday</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="8696255"/>
      <value value="6817202"/>
      <value value="1760526"/>
      <value value="2819562"/>
      <value value="8688328"/>
      <value value="523051"/>
      <value value="1481434"/>
      <value value="6018661"/>
      <value value="4583102"/>
      <value value="5322078"/>
      <value value="5479601"/>
      <value value="600285"/>
      <value value="8136616"/>
      <value value="6457144"/>
      <value value="7379635"/>
      <value value="9374771"/>
      <value value="1288194"/>
      <value value="1268071"/>
      <value value="5600662"/>
      <value value="4074780"/>
      <value value="1958957"/>
      <value value="3945074"/>
      <value value="3804824"/>
      <value value="8017444"/>
      <value value="6172597"/>
      <value value="614713"/>
      <value value="1107215"/>
      <value value="6981190"/>
      <value value="3939585"/>
      <value value="8273260"/>
      <value value="4970784"/>
      <value value="4028058"/>
      <value value="2882209"/>
      <value value="2884173"/>
      <value value="851231"/>
      <value value="9464270"/>
      <value value="5695629"/>
      <value value="7366662"/>
      <value value="7223744"/>
      <value value="6598584"/>
      <value value="5451919"/>
      <value value="5070215"/>
      <value value="3556305"/>
      <value value="4618529"/>
      <value value="4631"/>
      <value value="5826613"/>
      <value value="4427311"/>
      <value value="3426846"/>
      <value value="2104011"/>
      <value value="8261460"/>
      <value value="5234402"/>
      <value value="1431201"/>
      <value value="543080"/>
      <value value="6706633"/>
      <value value="6102542"/>
      <value value="277091"/>
      <value value="457668"/>
      <value value="6289458"/>
      <value value="8822023"/>
      <value value="551468"/>
      <value value="4532331"/>
      <value value="1340127"/>
      <value value="2544617"/>
      <value value="1360632"/>
      <value value="8686493"/>
      <value value="163091"/>
      <value value="7198507"/>
      <value value="6687034"/>
      <value value="5017826"/>
      <value value="4377641"/>
      <value value="9968025"/>
      <value value="6131404"/>
      <value value="4623906"/>
      <value value="3760871"/>
      <value value="2259514"/>
      <value value="3397557"/>
      <value value="4088733"/>
      <value value="700559"/>
      <value value="4420481"/>
      <value value="9609508"/>
      <value value="9703470"/>
      <value value="1409547"/>
      <value value="5316111"/>
      <value value="947161"/>
      <value value="4223146"/>
      <value value="9050517"/>
      <value value="5086179"/>
      <value value="4612337"/>
      <value value="4134300"/>
      <value value="8304649"/>
      <value value="9665804"/>
      <value value="5408084"/>
      <value value="1216955"/>
      <value value="9595146"/>
      <value value="6135182"/>
      <value value="8994641"/>
      <value value="8249462"/>
      <value value="8622255"/>
      <value value="7747301"/>
      <value value="9081326"/>
      <value value="4373119"/>
      <value value="9791722"/>
      <value value="6757422"/>
      <value value="8450947"/>
      <value value="5577599"/>
      <value value="7317442"/>
      <value value="573074"/>
      <value value="4306824"/>
      <value value="493947"/>
      <value value="665591"/>
      <value value="4835671"/>
      <value value="9875588"/>
      <value value="2900294"/>
      <value value="9556470"/>
      <value value="1988114"/>
      <value value="7885399"/>
      <value value="7215200"/>
      <value value="350755"/>
      <value value="467081"/>
      <value value="5240258"/>
      <value value="7333580"/>
      <value value="2304601"/>
      <value value="9868299"/>
      <value value="968302"/>
      <value value="2101073"/>
      <value value="1293045"/>
      <value value="4246109"/>
      <value value="9452928"/>
      <value value="2589638"/>
      <value value="4146371"/>
      <value value="2601132"/>
      <value value="4061445"/>
      <value value="5941992"/>
      <value value="7221784"/>
      <value value="1326080"/>
      <value value="8629117"/>
      <value value="6742932"/>
      <value value="4467363"/>
      <value value="9549279"/>
      <value value="7384696"/>
      <value value="5152042"/>
      <value value="8758089"/>
      <value value="8375543"/>
      <value value="6611524"/>
      <value value="5782139"/>
      <value value="5127036"/>
      <value value="9021752"/>
      <value value="538945"/>
      <value value="4748890"/>
      <value value="8064001"/>
      <value value="5608295"/>
      <value value="4619136"/>
      <value value="7795043"/>
      <value value="8593412"/>
      <value value="8986530"/>
      <value value="6934288"/>
      <value value="9539631"/>
      <value value="975683"/>
      <value value="6917994"/>
      <value value="9479170"/>
      <value value="2891245"/>
      <value value="5912226"/>
      <value value="8908634"/>
      <value value="1828188"/>
      <value value="8176507"/>
      <value value="7622372"/>
      <value value="6221579"/>
      <value value="2646146"/>
      <value value="8933549"/>
      <value value="8754446"/>
      <value value="7111527"/>
      <value value="2931076"/>
      <value value="2149356"/>
      <value value="4254152"/>
      <value value="1413534"/>
      <value value="3821899"/>
      <value value="6099610"/>
      <value value="2757067"/>
      <value value="171172"/>
      <value value="2366050"/>
      <value value="6682936"/>
      <value value="9454517"/>
      <value value="6448627"/>
      <value value="8709404"/>
      <value value="5328654"/>
      <value value="4165476"/>
      <value value="7697053"/>
      <value value="7418199"/>
      <value value="8095346"/>
      <value value="1652741"/>
      <value value="7745482"/>
      <value value="3014240"/>
      <value value="8251635"/>
      <value value="5379085"/>
      <value value="414434"/>
      <value value="9157249"/>
      <value value="3806152"/>
      <value value="6535986"/>
      <value value="2406484"/>
      <value value="2215952"/>
      <value value="202755"/>
      <value value="8923768"/>
      <value value="3234006"/>
      <value value="4581138"/>
      <value value="5416193"/>
      <value value="2442708"/>
      <value value="6484140"/>
      <value value="3479632"/>
      <value value="9200309"/>
      <value value="318488"/>
      <value value="6931696"/>
      <value value="8603565"/>
      <value value="8463412"/>
      <value value="4625278"/>
      <value value="9858642"/>
      <value value="3320180"/>
      <value value="9928818"/>
      <value value="274717"/>
      <value value="3546459"/>
      <value value="5493696"/>
      <value value="9230043"/>
      <value value="5500722"/>
      <value value="7314785"/>
      <value value="3143123"/>
      <value value="5294275"/>
      <value value="7511927"/>
      <value value="9324352"/>
      <value value="7629915"/>
      <value value="6737637"/>
      <value value="6658157"/>
      <value value="9159030"/>
      <value value="9127381"/>
      <value value="7726950"/>
      <value value="6350139"/>
      <value value="2956292"/>
      <value value="7118554"/>
      <value value="9226968"/>
      <value value="1645243"/>
      <value value="6226237"/>
      <value value="4538466"/>
      <value value="1064504"/>
      <value value="6651728"/>
      <value value="1358217"/>
      <value value="3009577"/>
      <value value="1589630"/>
      <value value="7146966"/>
      <value value="7418922"/>
      <value value="8634044"/>
      <value value="4880282"/>
      <value value="3064701"/>
      <value value="2004932"/>
      <value value="3208432"/>
      <value value="3183177"/>
      <value value="5801579"/>
      <value value="5837820"/>
      <value value="1257636"/>
      <value value="4562005"/>
      <value value="1768445"/>
      <value value="6446725"/>
      <value value="6519237"/>
      <value value="3009994"/>
      <value value="373616"/>
      <value value="8522943"/>
      <value value="8072385"/>
      <value value="9763808"/>
      <value value="6677802"/>
      <value value="1449783"/>
      <value value="9494521"/>
      <value value="6083958"/>
      <value value="9486894"/>
      <value value="335186"/>
      <value value="7866924"/>
      <value value="8843121"/>
      <value value="325391"/>
      <value value="4662424"/>
      <value value="7381763"/>
      <value value="699355"/>
      <value value="6068024"/>
      <value value="6200638"/>
      <value value="6603491"/>
      <value value="1154371"/>
      <value value="3537272"/>
      <value value="1079049"/>
      <value value="432683"/>
      <value value="9217622"/>
      <value value="9747959"/>
      <value value="5202764"/>
      <value value="7953535"/>
      <value value="8181267"/>
      <value value="187527"/>
      <value value="7679945"/>
      <value value="9287036"/>
      <value value="2732372"/>
      <value value="3887263"/>
      <value value="4598332"/>
      <value value="419332"/>
      <value value="2371091"/>
      <value value="1821671"/>
      <value value="7093006"/>
      <value value="8611490"/>
      <value value="940407"/>
      <value value="7803589"/>
      <value value="3298396"/>
      <value value="7024455"/>
      <value value="88727"/>
      <value value="5106744"/>
      <value value="3777053"/>
      <value value="9316804"/>
      <value value="9935991"/>
      <value value="1165970"/>
      <value value="7381187"/>
      <value value="4268593"/>
      <value value="2036843"/>
      <value value="507972"/>
      <value value="7705787"/>
      <value value="824839"/>
      <value value="3479383"/>
      <value value="1158428"/>
      <value value="9709871"/>
      <value value="2891709"/>
      <value value="4021258"/>
      <value value="1650811"/>
      <value value="9694939"/>
      <value value="1902664"/>
      <value value="4966165"/>
      <value value="8676872"/>
      <value value="3871516"/>
      <value value="4249411"/>
      <value value="2886915"/>
      <value value="6420831"/>
      <value value="3722131"/>
      <value value="1295793"/>
      <value value="1709784"/>
      <value value="8139513"/>
      <value value="7292672"/>
      <value value="3838216"/>
      <value value="6909633"/>
      <value value="1463887"/>
      <value value="1904381"/>
      <value value="679622"/>
      <value value="2436893"/>
      <value value="7528314"/>
      <value value="1350197"/>
      <value value="1669269"/>
      <value value="5710169"/>
      <value value="3800696"/>
      <value value="732986"/>
      <value value="1794600"/>
      <value value="2948518"/>
      <value value="9367170"/>
      <value value="8704770"/>
      <value value="6335974"/>
      <value value="1845313"/>
      <value value="1413361"/>
      <value value="5321001"/>
      <value value="18757"/>
      <value value="1257700"/>
      <value value="5434624"/>
      <value value="766246"/>
      <value value="8586409"/>
      <value value="3675484"/>
      <value value="965302"/>
      <value value="3644198"/>
      <value value="7468851"/>
      <value value="6669"/>
      <value value="1143114"/>
      <value value="1190682"/>
      <value value="536547"/>
      <value value="5851635"/>
      <value value="9759404"/>
      <value value="7593202"/>
      <value value="1841663"/>
      <value value="4148837"/>
      <value value="8114628"/>
      <value value="1626521"/>
      <value value="8382683"/>
      <value value="3370256"/>
      <value value="9048912"/>
      <value value="6190336"/>
      <value value="5649480"/>
      <value value="1672863"/>
      <value value="3713505"/>
      <value value="3500169"/>
      <value value="7466921"/>
      <value value="9424454"/>
      <value value="728074"/>
      <value value="6439870"/>
      <value value="1541294"/>
      <value value="9810196"/>
      <value value="8862966"/>
      <value value="8092266"/>
      <value value="1575226"/>
      <value value="2161966"/>
      <value value="6393010"/>
      <value value="8809238"/>
      <value value="2431029"/>
      <value value="4536181"/>
      <value value="9204997"/>
      <value value="1972601"/>
      <value value="6231097"/>
      <value value="4730672"/>
      <value value="6729261"/>
      <value value="6068089"/>
      <value value="1882109"/>
      <value value="563366"/>
      <value value="7622691"/>
      <value value="2888799"/>
      <value value="8495919"/>
      <value value="73953"/>
      <value value="6101666"/>
      <value value="9186414"/>
      <value value="6352135"/>
      <value value="4710023"/>
      <value value="2671102"/>
      <value value="9175939"/>
      <value value="4194209"/>
      <value value="2047328"/>
      <value value="5525462"/>
      <value value="7723585"/>
      <value value="4180275"/>
      <value value="1248381"/>
      <value value="6838893"/>
      <value value="5396551"/>
      <value value="7255286"/>
      <value value="6243364"/>
      <value value="7971184"/>
      <value value="4801573"/>
      <value value="6355045"/>
      <value value="3949419"/>
      <value value="2992360"/>
      <value value="8364310"/>
      <value value="5138940"/>
      <value value="982401"/>
      <value value="4974063"/>
      <value value="3914620"/>
      <value value="803921"/>
      <value value="4802739"/>
      <value value="4188749"/>
      <value value="672979"/>
      <value value="1183439"/>
      <value value="5771110"/>
      <value value="7747932"/>
      <value value="1696948"/>
      <value value="88915"/>
      <value value="6275344"/>
      <value value="9583451"/>
      <value value="8236467"/>
      <value value="4656370"/>
      <value value="7395884"/>
      <value value="2019835"/>
      <value value="7168194"/>
      <value value="4327965"/>
      <value value="2919646"/>
      <value value="7611778"/>
      <value value="416234"/>
      <value value="72700"/>
      <value value="5117116"/>
      <value value="5647394"/>
      <value value="2941480"/>
      <value value="8132845"/>
      <value value="2006537"/>
      <value value="1620830"/>
      <value value="7449675"/>
      <value value="2135233"/>
      <value value="7995437"/>
      <value value="5773224"/>
      <value value="8615716"/>
      <value value="2331237"/>
      <value value="2474130"/>
      <value value="7076142"/>
      <value value="5585520"/>
      <value value="2152476"/>
      <value value="3875245"/>
      <value value="1005398"/>
      <value value="4017681"/>
      <value value="5562257"/>
      <value value="9784453"/>
      <value value="6190929"/>
      <value value="8451911"/>
      <value value="9660401"/>
      <value value="1426335"/>
      <value value="5902444"/>
      <value value="7086943"/>
      <value value="5509838"/>
      <value value="9344280"/>
      <value value="4974173"/>
      <value value="2103828"/>
      <value value="4098867"/>
      <value value="3667408"/>
      <value value="5073302"/>
      <value value="9969011"/>
      <value value="5426025"/>
      <value value="5751565"/>
      <value value="5061295"/>
      <value value="1739836"/>
      <value value="236871"/>
      <value value="8932141"/>
      <value value="758630"/>
      <value value="4406825"/>
      <value value="2321317"/>
      <value value="8978902"/>
      <value value="8089918"/>
      <value value="5708556"/>
      <value value="8679267"/>
      <value value="3386001"/>
      <value value="6392572"/>
      <value value="7666470"/>
      <value value="3764232"/>
      <value value="8273346"/>
      <value value="1641313"/>
      <value value="1116102"/>
      <value value="2963731"/>
      <value value="2116529"/>
      <value value="4911629"/>
      <value value="6423378"/>
      <value value="5475887"/>
      <value value="2978087"/>
      <value value="3863736"/>
      <value value="6008506"/>
      <value value="905329"/>
      <value value="4299551"/>
      <value value="3850425"/>
      <value value="4295755"/>
      <value value="9883260"/>
      <value value="4747425"/>
      <value value="1278668"/>
      <value value="3803398"/>
      <value value="6539719"/>
      <value value="6330015"/>
      <value value="239146"/>
      <value value="4421387"/>
      <value value="2443005"/>
      <value value="6436804"/>
      <value value="55301"/>
      <value value="8709263"/>
      <value value="8068210"/>
      <value value="9334407"/>
      <value value="3205144"/>
      <value value="8152810"/>
      <value value="5418579"/>
      <value value="9558060"/>
      <value value="6771711"/>
      <value value="6461860"/>
      <value value="3071403"/>
      <value value="5108503"/>
      <value value="5392865"/>
      <value value="2366380"/>
      <value value="1392774"/>
      <value value="9695420"/>
      <value value="8901347"/>
      <value value="7595930"/>
      <value value="8081161"/>
      <value value="6177505"/>
      <value value="7770879"/>
      <value value="3939001"/>
      <value value="809368"/>
      <value value="7115469"/>
      <value value="1602010"/>
      <value value="2304330"/>
      <value value="4042207"/>
      <value value="9787868"/>
      <value value="8647557"/>
      <value value="7739998"/>
      <value value="6225767"/>
      <value value="9209814"/>
      <value value="5200562"/>
      <value value="2082275"/>
      <value value="7973919"/>
      <value value="6981932"/>
      <value value="2071769"/>
      <value value="8597746"/>
      <value value="5543230"/>
      <value value="7853733"/>
      <value value="5675432"/>
      <value value="602235"/>
      <value value="4194112"/>
      <value value="7814055"/>
      <value value="2324870"/>
      <value value="8721118"/>
      <value value="5544634"/>
      <value value="3280658"/>
      <value value="4406312"/>
      <value value="4874660"/>
      <value value="1210175"/>
      <value value="3851551"/>
      <value value="6082943"/>
      <value value="471300"/>
      <value value="6895376"/>
      <value value="119849"/>
      <value value="745284"/>
      <value value="9246600"/>
      <value value="6518773"/>
      <value value="2910026"/>
      <value value="4832820"/>
      <value value="8491218"/>
      <value value="6452433"/>
      <value value="6471373"/>
      <value value="1445361"/>
      <value value="9663065"/>
      <value value="5817579"/>
      <value value="9387311"/>
      <value value="7786916"/>
      <value value="5347678"/>
      <value value="8701721"/>
      <value value="9593022"/>
      <value value="3667008"/>
      <value value="400220"/>
      <value value="520508"/>
      <value value="7449716"/>
      <value value="6710381"/>
      <value value="9044923"/>
      <value value="5403433"/>
      <value value="3433814"/>
      <value value="2691904"/>
      <value value="3006386"/>
      <value value="8216967"/>
      <value value="13493"/>
      <value value="7807547"/>
      <value value="5300390"/>
      <value value="1850291"/>
      <value value="8961721"/>
      <value value="5615175"/>
      <value value="366976"/>
      <value value="330407"/>
      <value value="9337743"/>
      <value value="5364544"/>
      <value value="5316975"/>
      <value value="1963220"/>
      <value value="5925593"/>
      <value value="9172981"/>
      <value value="4089459"/>
      <value value="3649407"/>
      <value value="3211910"/>
      <value value="9116243"/>
      <value value="8402464"/>
      <value value="2403491"/>
      <value value="4835767"/>
      <value value="3922926"/>
      <value value="8299021"/>
      <value value="228794"/>
      <value value="1703954"/>
      <value value="6006031"/>
      <value value="8398380"/>
      <value value="7110431"/>
      <value value="3900402"/>
      <value value="1479297"/>
      <value value="7007399"/>
      <value value="5660784"/>
      <value value="3948692"/>
      <value value="1061771"/>
      <value value="9346906"/>
      <value value="3892138"/>
      <value value="4830484"/>
      <value value="1575596"/>
      <value value="6261898"/>
      <value value="126967"/>
      <value value="9499964"/>
      <value value="6473120"/>
      <value value="3945928"/>
      <value value="833458"/>
      <value value="2720315"/>
      <value value="8055409"/>
      <value value="2404657"/>
      <value value="4962335"/>
      <value value="2406344"/>
      <value value="7715467"/>
      <value value="23225"/>
      <value value="4871531"/>
      <value value="9940026"/>
      <value value="2258028"/>
      <value value="5390631"/>
      <value value="7505549"/>
      <value value="6824503"/>
      <value value="7245419"/>
      <value value="2504030"/>
      <value value="2368506"/>
      <value value="2666339"/>
      <value value="266871"/>
      <value value="6480956"/>
      <value value="9393926"/>
      <value value="3199459"/>
      <value value="4245971"/>
      <value value="1734431"/>
      <value value="6749222"/>
      <value value="5469315"/>
      <value value="2743961"/>
      <value value="9807342"/>
      <value value="9033034"/>
      <value value="6362511"/>
      <value value="2907049"/>
      <value value="965269"/>
      <value value="2589883"/>
      <value value="1059190"/>
      <value value="4005788"/>
      <value value="2211476"/>
      <value value="57024"/>
      <value value="7571759"/>
      <value value="3839174"/>
      <value value="9961922"/>
      <value value="4603321"/>
      <value value="6090330"/>
      <value value="1762649"/>
      <value value="7648771"/>
      <value value="2589497"/>
      <value value="6064685"/>
      <value value="4512127"/>
      <value value="9801289"/>
      <value value="2941022"/>
      <value value="5016190"/>
      <value value="460592"/>
      <value value="4044741"/>
      <value value="7708423"/>
      <value value="6501239"/>
      <value value="4580264"/>
      <value value="2860924"/>
      <value value="6036294"/>
      <value value="9164381"/>
      <value value="7203005"/>
      <value value="6629624"/>
      <value value="5333339"/>
      <value value="6189784"/>
      <value value="4474838"/>
      <value value="7352902"/>
      <value value="1365500"/>
      <value value="401697"/>
      <value value="3112076"/>
      <value value="1442047"/>
      <value value="2982961"/>
      <value value="9237172"/>
      <value value="654129"/>
      <value value="4214308"/>
      <value value="9885525"/>
      <value value="7539221"/>
      <value value="8890308"/>
      <value value="5686585"/>
      <value value="8832496"/>
      <value value="4682154"/>
      <value value="5860926"/>
      <value value="4749481"/>
      <value value="4257053"/>
      <value value="8508371"/>
      <value value="4783252"/>
      <value value="4989691"/>
      <value value="2757109"/>
      <value value="7895871"/>
      <value value="1720865"/>
      <value value="5543776"/>
      <value value="4046490"/>
      <value value="9818030"/>
      <value value="1445777"/>
      <value value="6399897"/>
      <value value="8480273"/>
      <value value="3996116"/>
      <value value="7577939"/>
      <value value="9162865"/>
      <value value="7615230"/>
      <value value="7481257"/>
      <value value="2617133"/>
      <value value="3127543"/>
      <value value="2833084"/>
      <value value="1046132"/>
      <value value="3070278"/>
      <value value="8954648"/>
      <value value="5775492"/>
      <value value="6171441"/>
      <value value="2052622"/>
      <value value="194297"/>
      <value value="4788064"/>
      <value value="4275048"/>
      <value value="6646061"/>
      <value value="7675711"/>
      <value value="409030"/>
      <value value="1093208"/>
      <value value="9012099"/>
      <value value="1528313"/>
      <value value="1662415"/>
      <value value="9700749"/>
      <value value="8113892"/>
      <value value="808663"/>
      <value value="2136084"/>
      <value value="717716"/>
      <value value="9350844"/>
      <value value="6090870"/>
      <value value="5956125"/>
      <value value="6682448"/>
      <value value="3379551"/>
      <value value="4104808"/>
      <value value="458545"/>
      <value value="9584315"/>
      <value value="4551669"/>
      <value value="4774559"/>
      <value value="9785589"/>
      <value value="3090172"/>
      <value value="8064166"/>
      <value value="1854915"/>
      <value value="7256901"/>
      <value value="4573917"/>
      <value value="2967772"/>
      <value value="2857806"/>
      <value value="2888842"/>
      <value value="6159269"/>
      <value value="8919269"/>
      <value value="8747163"/>
      <value value="317850"/>
      <value value="2319651"/>
      <value value="4722794"/>
      <value value="2437523"/>
      <value value="370097"/>
      <value value="3555795"/>
      <value value="2677097"/>
      <value value="6612811"/>
      <value value="8042917"/>
      <value value="4668205"/>
      <value value="9640323"/>
      <value value="6975103"/>
      <value value="9759758"/>
      <value value="6362226"/>
      <value value="6642602"/>
      <value value="4770638"/>
      <value value="2721445"/>
      <value value="337061"/>
      <value value="5810454"/>
      <value value="632776"/>
      <value value="6524273"/>
      <value value="2401838"/>
      <value value="4638192"/>
      <value value="3011420"/>
      <value value="6381232"/>
      <value value="8638933"/>
      <value value="1280343"/>
      <value value="2074515"/>
      <value value="5132821"/>
      <value value="1087397"/>
      <value value="9784319"/>
      <value value="7786726"/>
      <value value="8489986"/>
      <value value="9422561"/>
      <value value="8641322"/>
      <value value="9517521"/>
      <value value="6803958"/>
      <value value="6176987"/>
      <value value="1724507"/>
      <value value="858341"/>
      <value value="3506387"/>
      <value value="1550557"/>
      <value value="4705541"/>
      <value value="2378646"/>
      <value value="6604487"/>
      <value value="5036589"/>
      <value value="273781"/>
      <value value="7156903"/>
      <value value="1105496"/>
      <value value="8350450"/>
      <value value="9347814"/>
      <value value="5843439"/>
      <value value="3305261"/>
      <value value="2207846"/>
      <value value="5306132"/>
      <value value="4112889"/>
      <value value="3698373"/>
      <value value="2730142"/>
      <value value="9757186"/>
      <value value="4398967"/>
      <value value="107545"/>
      <value value="3787958"/>
      <value value="3207939"/>
      <value value="6236006"/>
      <value value="9349082"/>
      <value value="4860642"/>
      <value value="8204151"/>
      <value value="1692580"/>
      <value value="8516488"/>
      <value value="5233919"/>
      <value value="7988196"/>
      <value value="7341934"/>
      <value value="1436949"/>
      <value value="7071977"/>
      <value value="9618717"/>
      <value value="8533036"/>
      <value value="4137310"/>
      <value value="5694910"/>
      <value value="5714859"/>
      <value value="2748509"/>
      <value value="1430733"/>
      <value value="7228600"/>
      <value value="9415243"/>
      <value value="6942494"/>
      <value value="2807782"/>
      <value value="1842333"/>
      <value value="8477098"/>
      <value value="4307396"/>
      <value value="9001329"/>
      <value value="6146728"/>
      <value value="1092710"/>
      <value value="295749"/>
      <value value="3479272"/>
      <value value="1212374"/>
      <value value="4087430"/>
      <value value="3637740"/>
      <value value="8948962"/>
      <value value="5665908"/>
      <value value="721638"/>
      <value value="8528511"/>
      <value value="9167934"/>
      <value value="1505564"/>
      <value value="2790060"/>
      <value value="8545240"/>
      <value value="2897660"/>
      <value value="7384460"/>
      <value value="9626340"/>
      <value value="5396708"/>
      <value value="6040514"/>
      <value value="9217083"/>
      <value value="1575996"/>
      <value value="9642735"/>
      <value value="8918299"/>
      <value value="6473902"/>
      <value value="9249049"/>
      <value value="2878591"/>
      <value value="3268273"/>
      <value value="9518860"/>
      <value value="5405141"/>
      <value value="2547560"/>
      <value value="2032589"/>
      <value value="8006624"/>
      <value value="8416392"/>
      <value value="4345472"/>
      <value value="1929877"/>
      <value value="3326940"/>
      <value value="487862"/>
      <value value="8222687"/>
      <value value="8075453"/>
      <value value="8858975"/>
      <value value="8632661"/>
      <value value="3059784"/>
      <value value="52931"/>
      <value value="8952766"/>
      <value value="7257655"/>
      <value value="2014631"/>
      <value value="9457502"/>
      <value value="1588835"/>
      <value value="552272"/>
      <value value="4832764"/>
      <value value="520713"/>
      <value value="7739982"/>
      <value value="2107950"/>
      <value value="1208807"/>
      <value value="5764473"/>
      <value value="4600941"/>
      <value value="558632"/>
      <value value="1428899"/>
      <value value="4684635"/>
      <value value="6721759"/>
      <value value="1653236"/>
      <value value="5835541"/>
      <value value="5913864"/>
      <value value="2303075"/>
      <value value="29328"/>
      <value value="9263918"/>
      <value value="3548884"/>
      <value value="1307934"/>
      <value value="8348862"/>
      <value value="7453840"/>
      <value value="7368176"/>
      <value value="7811335"/>
      <value value="5715173"/>
      <value value="6817558"/>
      <value value="6865773"/>
      <value value="9365474"/>
      <value value="6914918"/>
      <value value="2502884"/>
      <value value="9957358"/>
      <value value="8043357"/>
      <value value="9068139"/>
      <value value="4621350"/>
      <value value="5078395"/>
      <value value="7292624"/>
      <value value="2641595"/>
      <value value="3321886"/>
      <value value="4204599"/>
      <value value="1666041"/>
      <value value="534632"/>
      <value value="9951959"/>
      <value value="3892434"/>
      <value value="6501807"/>
      <value value="6514727"/>
      <value value="2557329"/>
      <value value="3346646"/>
      <value value="7671345"/>
      <value value="5144906"/>
      <value value="393233"/>
      <value value="7702578"/>
      <value value="9770184"/>
      <value value="3368856"/>
      <value value="4793322"/>
      <value value="6408780"/>
      <value value="2170731"/>
      <value value="3834668"/>
      <value value="6801273"/>
      <value value="441395"/>
      <value value="3291250"/>
      <value value="7425879"/>
      <value value="7016463"/>
      <value value="4957154"/>
      <value value="2166734"/>
      <value value="7169013"/>
      <value value="903839"/>
      <value value="7752868"/>
      <value value="2154085"/>
      <value value="1651675"/>
      <value value="1211895"/>
      <value value="4317099"/>
      <value value="8293227"/>
      <value value="676406"/>
      <value value="6590298"/>
      <value value="5067427"/>
      <value value="3611514"/>
      <value value="3151247"/>
      <value value="5567660"/>
      <value value="2866886"/>
      <value value="7040402"/>
      <value value="9017820"/>
      <value value="8800532"/>
      <value value="4478208"/>
      <value value="6982574"/>
      <value value="6418780"/>
      <value value="1234995"/>
      <value value="7588011"/>
      <value value="8090079"/>
      <value value="4448522"/>
      <value value="4653754"/>
      <value value="6981756"/>
      <value value="895177"/>
      <value value="2520006"/>
      <value value="3701305"/>
      <value value="6357503"/>
      <value value="5626320"/>
      <value value="1133845"/>
      <value value="2772559"/>
      <value value="8379934"/>
      <value value="5261804"/>
      <value value="3553398"/>
      <value value="6088644"/>
      <value value="4819353"/>
      <value value="5319194"/>
      <value value="3065265"/>
      <value value="5188272"/>
      <value value="9565902"/>
      <value value="7847789"/>
      <value value="1179489"/>
      <value value="1799229"/>
      <value value="3099918"/>
      <value value="2738692"/>
      <value value="904756"/>
      <value value="3859701"/>
      <value value="2546155"/>
      <value value="6789003"/>
      <value value="9828654"/>
      <value value="6567041"/>
      <value value="4315147"/>
      <value value="8353141"/>
      <value value="2276143"/>
      <value value="5695674"/>
      <value value="8574583"/>
      <value value="5471132"/>
      <value value="3852794"/>
      <value value="4013824"/>
      <value value="722619"/>
      <value value="9845340"/>
      <value value="7359199"/>
      <value value="5708984"/>
      <value value="1231156"/>
      <value value="4258895"/>
      <value value="7660268"/>
      <value value="5301368"/>
      <value value="4400925"/>
      <value value="1113856"/>
      <value value="2433991"/>
      <value value="6551731"/>
      <value value="2146319"/>
      <value value="6449504"/>
      <value value="6972679"/>
      <value value="3872333"/>
      <value value="2051426"/>
      <value value="6658994"/>
      <value value="2071732"/>
      <value value="4541819"/>
      <value value="8466819"/>
      <value value="3299999"/>
      <value value="1445811"/>
      <value value="191685"/>
      <value value="4366068"/>
      <value value="8452245"/>
      <value value="917489"/>
      <value value="1829943"/>
      <value value="6470247"/>
      <value value="1436338"/>
      <value value="2708664"/>
      <value value="982274"/>
      <value value="1963598"/>
      <value value="8961210"/>
      <value value="5143114"/>
      <value value="8046953"/>
      <value value="802134"/>
      <value value="2948783"/>
      <value value="8704412"/>
      <value value="4650037"/>
      <value value="446540"/>
      <value value="3381140"/>
      <value value="4545614"/>
      <value value="1204386"/>
      <value value="9711950"/>
      <value value="1162336"/>
      <value value="9415922"/>
      <value value="5384533"/>
      <value value="3477687"/>
      <value value="6529772"/>
      <value value="9272183"/>
      <value value="6332410"/>
      <value value="3485503"/>
      <value value="4033553"/>
      <value value="9192043"/>
      <value value="7139408"/>
      <value value="9934680"/>
      <value value="5213603"/>
      <value value="2481875"/>
      <value value="3460145"/>
      <value value="3614147"/>
      <value value="6224219"/>
      <value value="8519246"/>
      <value value="6446365"/>
      <value value="5935727"/>
      <value value="8403282"/>
      <value value="1331533"/>
      <value value="6557786"/>
      <value value="7124035"/>
      <value value="6369758"/>
      <value value="8541590"/>
      <value value="9995966"/>
      <value value="7670552"/>
      <value value="3661971"/>
      <value value="5664598"/>
      <value value="7431768"/>
      <value value="370937"/>
      <value value="4826999"/>
      <value value="5103588"/>
      <value value="5756104"/>
      <value value="2184403"/>
      <value value="448741"/>
      <value value="798401"/>
      <value value="4466458"/>
      <value value="7436491"/>
      <value value="1036521"/>
      <value value="6447678"/>
      <value value="9580469"/>
      <value value="4952424"/>
      <value value="5675615"/>
      <value value="3746975"/>
      <value value="1179452"/>
      <value value="6121088"/>
      <value value="4719771"/>
      <value value="6023907"/>
      <value value="2426065"/>
      <value value="2183512"/>
      <value value="9695005"/>
      <value value="4299850"/>
      <value value="4306746"/>
      <value value="1738051"/>
      <value value="6302351"/>
      <value value="3405095"/>
      <value value="7472339"/>
      <value value="8599856"/>
      <value value="2327562"/>
      <value value="7771512"/>
      <value value="1204348"/>
      <value value="5199582"/>
      <value value="7622100"/>
      <value value="9767181"/>
      <value value="8363886"/>
      <value value="2920903"/>
      <value value="5045629"/>
      <value value="5174571"/>
      <value value="9053256"/>
      <value value="482339"/>
      <value value="2976782"/>
      <value value="8130173"/>
      <value value="8950041"/>
      <value value="3764449"/>
      <value value="6690974"/>
      <value value="7068093"/>
      <value value="2178651"/>
      <value value="2668820"/>
      <value value="9715263"/>
      <value value="2061478"/>
      <value value="3644864"/>
      <value value="276497"/>
      <value value="9786783"/>
      <value value="3099822"/>
      <value value="3129405"/>
      <value value="1938016"/>
      <value value="5185018"/>
      <value value="4994064"/>
      <value value="2085830"/>
      <value value="8942241"/>
      <value value="7628306"/>
      <value value="5868502"/>
      <value value="7574710"/>
      <value value="2762398"/>
      <value value="7033250"/>
      <value value="2742686"/>
      <value value="3944616"/>
      <value value="3375247"/>
      <value value="9962651"/>
      <value value="7284677"/>
      <value value="7782130"/>
      <value value="2518203"/>
      <value value="6282804"/>
      <value value="785889"/>
      <value value="4962669"/>
      <value value="8895327"/>
      <value value="9977149"/>
      <value value="7639141"/>
      <value value="8144897"/>
      <value value="6961672"/>
      <value value="4043146"/>
      <value value="7527030"/>
      <value value="844042"/>
      <value value="3879458"/>
      <value value="5197493"/>
      <value value="3873026"/>
      <value value="7587116"/>
      <value value="4005567"/>
      <value value="1777593"/>
      <value value="4925605"/>
      <value value="2667604"/>
      <value value="6304301"/>
      <value value="106913"/>
      <value value="4710901"/>
      <value value="4803429"/>
      <value value="1710644"/>
      <value value="5020497"/>
      <value value="3411583"/>
      <value value="3141558"/>
      <value value="4914980"/>
      <value value="3480712"/>
      <value value="8564343"/>
      <value value="1554789"/>
      <value value="2921375"/>
      <value value="1679"/>
      <value value="2693060"/>
      <value value="8262828"/>
      <value value="9344809"/>
      <value value="7229893"/>
      <value value="1483139"/>
      <value value="2827225"/>
      <value value="5972867"/>
      <value value="1142784"/>
      <value value="7942630"/>
      <value value="5491518"/>
      <value value="4909122"/>
      <value value="851397"/>
      <value value="3814686"/>
      <value value="6357161"/>
      <value value="5247152"/>
      <value value="5621913"/>
      <value value="7221566"/>
      <value value="3297497"/>
      <value value="421794"/>
      <value value="2505180"/>
      <value value="5903968"/>
      <value value="3069086"/>
      <value value="7715974"/>
      <value value="3590413"/>
      <value value="1963795"/>
      <value value="9354199"/>
      <value value="9379008"/>
      <value value="7383367"/>
      <value value="7745318"/>
      <value value="4086397"/>
      <value value="964680"/>
      <value value="184025"/>
      <value value="4647234"/>
      <value value="2356267"/>
      <value value="1878699"/>
      <value value="6484555"/>
      <value value="2405791"/>
      <value value="5449243"/>
      <value value="349397"/>
      <value value="4774297"/>
      <value value="4427878"/>
      <value value="3385835"/>
      <value value="5884279"/>
      <value value="9604077"/>
      <value value="7874257"/>
      <value value="1600829"/>
      <value value="9041462"/>
      <value value="8103336"/>
      <value value="1577838"/>
      <value value="6053312"/>
      <value value="2375531"/>
      <value value="6705157"/>
      <value value="26049"/>
      <value value="9284270"/>
      <value value="5121092"/>
      <value value="3975086"/>
      <value value="6243720"/>
      <value value="4373310"/>
      <value value="8037239"/>
      <value value="5666097"/>
      <value value="6772020"/>
      <value value="1273047"/>
      <value value="6872231"/>
      <value value="1503735"/>
      <value value="4768617"/>
      <value value="3276350"/>
      <value value="3893827"/>
      <value value="4820975"/>
      <value value="4444198"/>
      <value value="6287548"/>
      <value value="54673"/>
      <value value="4749520"/>
      <value value="2188200"/>
      <value value="3747301"/>
      <value value="5869524"/>
      <value value="1718871"/>
      <value value="1512873"/>
      <value value="6715998"/>
      <value value="4935545"/>
      <value value="5411493"/>
      <value value="9996980"/>
      <value value="4297229"/>
      <value value="7778137"/>
      <value value="4397134"/>
      <value value="2265692"/>
      <value value="6524076"/>
      <value value="1685044"/>
      <value value="629854"/>
      <value value="6803962"/>
      <value value="5963185"/>
      <value value="2120959"/>
      <value value="7104242"/>
      <value value="2980524"/>
      <value value="5564862"/>
      <value value="9148010"/>
      <value value="5472387"/>
      <value value="1606333"/>
      <value value="8889515"/>
      <value value="399027"/>
      <value value="3001791"/>
      <value value="9991514"/>
      <value value="7756099"/>
      <value value="8112631"/>
      <value value="6217563"/>
      <value value="8085920"/>
      <value value="1546896"/>
      <value value="9957394"/>
      <value value="746380"/>
      <value value="733231"/>
      <value value="9230364"/>
      <value value="6938140"/>
      <value value="4470317"/>
      <value value="949397"/>
      <value value="6673804"/>
      <value value="3956256"/>
      <value value="5199355"/>
      <value value="2632478"/>
      <value value="8216827"/>
      <value value="8200147"/>
      <value value="3096675"/>
      <value value="9291246"/>
      <value value="3223848"/>
      <value value="5825439"/>
      <value value="5463011"/>
      <value value="3043222"/>
      <value value="9408035"/>
      <value value="9726933"/>
      <value value="3086200"/>
      <value value="1339850"/>
      <value value="5986862"/>
      <value value="1680280"/>
      <value value="9017492"/>
      <value value="4909309"/>
      <value value="7758286"/>
      <value value="1391533"/>
      <value value="2000096"/>
      <value value="3348526"/>
      <value value="7753397"/>
      <value value="3639202"/>
      <value value="9099252"/>
      <value value="1230793"/>
      <value value="8777862"/>
      <value value="7773755"/>
      <value value="9682125"/>
      <value value="7361459"/>
      <value value="3215867"/>
      <value value="1428800"/>
      <value value="6051204"/>
      <value value="3629236"/>
      <value value="2134138"/>
      <value value="5947746"/>
      <value value="8436112"/>
      <value value="7911492"/>
      <value value="463760"/>
      <value value="6480097"/>
      <value value="3170393"/>
      <value value="9042938"/>
      <value value="4519248"/>
      <value value="2389416"/>
      <value value="3415884"/>
      <value value="4669166"/>
      <value value="9758021"/>
      <value value="4904328"/>
      <value value="4345694"/>
      <value value="858569"/>
      <value value="9007972"/>
      <value value="6503359"/>
      <value value="5818649"/>
      <value value="8161553"/>
      <value value="6542114"/>
      <value value="7845467"/>
      <value value="1421479"/>
      <value value="7163748"/>
      <value value="9957855"/>
      <value value="925157"/>
      <value value="4095602"/>
      <value value="3913720"/>
      <value value="8380100"/>
      <value value="8794764"/>
      <value value="7892146"/>
      <value value="2688454"/>
      <value value="9922738"/>
      <value value="4272240"/>
      <value value="7290525"/>
      <value value="2556320"/>
      <value value="3148190"/>
      <value value="5973969"/>
      <value value="8024500"/>
      <value value="2580729"/>
      <value value="3045173"/>
      <value value="8339109"/>
      <value value="846277"/>
      <value value="6578454"/>
      <value value="50426"/>
      <value value="9319187"/>
      <value value="9250973"/>
      <value value="5446244"/>
      <value value="564847"/>
      <value value="1304341"/>
      <value value="364661"/>
      <value value="8162436"/>
      <value value="9580475"/>
      <value value="6266152"/>
      <value value="376973"/>
      <value value="2193482"/>
      <value value="3358166"/>
      <value value="5053520"/>
      <value value="1961435"/>
      <value value="2826172"/>
      <value value="8986817"/>
      <value value="2715495"/>
      <value value="5416430"/>
      <value value="9667553"/>
      <value value="7122279"/>
      <value value="6725978"/>
      <value value="3974832"/>
      <value value="5550930"/>
      <value value="6122551"/>
      <value value="437397"/>
      <value value="9954686"/>
      <value value="846018"/>
      <value value="6505064"/>
      <value value="4697192"/>
      <value value="2354172"/>
      <value value="1208409"/>
      <value value="861151"/>
      <value value="8470239"/>
      <value value="8579574"/>
      <value value="2357369"/>
      <value value="6696526"/>
      <value value="8827498"/>
      <value value="8248819"/>
      <value value="5798699"/>
      <value value="2996781"/>
      <value value="9294518"/>
      <value value="2666848"/>
      <value value="4349168"/>
      <value value="1731508"/>
      <value value="4606904"/>
      <value value="552729"/>
      <value value="6044372"/>
      <value value="8788837"/>
      <value value="6520544"/>
      <value value="3400019"/>
      <value value="9836112"/>
      <value value="466454"/>
      <value value="7161716"/>
      <value value="4409540"/>
      <value value="2171317"/>
      <value value="790822"/>
      <value value="4424501"/>
      <value value="16645"/>
      <value value="8816258"/>
      <value value="9065305"/>
      <value value="4291671"/>
      <value value="2957941"/>
      <value value="7377901"/>
      <value value="2417676"/>
      <value value="890070"/>
      <value value="495893"/>
      <value value="1289027"/>
      <value value="2854829"/>
      <value value="4415010"/>
      <value value="7722970"/>
      <value value="2918687"/>
      <value value="9823789"/>
      <value value="913951"/>
      <value value="6890737"/>
      <value value="7411025"/>
      <value value="2905021"/>
      <value value="6817092"/>
      <value value="718384"/>
      <value value="4293455"/>
      <value value="7981778"/>
      <value value="4458286"/>
      <value value="7704281"/>
      <value value="8617536"/>
      <value value="7455873"/>
      <value value="5883436"/>
      <value value="127442"/>
      <value value="5175204"/>
      <value value="1583287"/>
      <value value="5491750"/>
      <value value="1898992"/>
      <value value="7853402"/>
      <value value="5320220"/>
      <value value="5696859"/>
      <value value="3762411"/>
      <value value="9188166"/>
      <value value="7259275"/>
      <value value="1862064"/>
      <value value="3663296"/>
      <value value="6790502"/>
      <value value="7076251"/>
      <value value="9224208"/>
      <value value="2783129"/>
      <value value="5312609"/>
      <value value="3565894"/>
      <value value="7793659"/>
      <value value="4534770"/>
      <value value="2875525"/>
      <value value="4440337"/>
      <value value="8414338"/>
      <value value="654697"/>
      <value value="9091953"/>
      <value value="9482034"/>
      <value value="8769670"/>
      <value value="6292511"/>
      <value value="699517"/>
      <value value="888104"/>
      <value value="5662571"/>
      <value value="8377561"/>
      <value value="6193524"/>
      <value value="8148869"/>
      <value value="3225658"/>
      <value value="6843466"/>
      <value value="8247071"/>
      <value value="6303203"/>
      <value value="5479730"/>
      <value value="81830"/>
      <value value="7725608"/>
      <value value="2346569"/>
      <value value="1084384"/>
      <value value="6808878"/>
      <value value="9488258"/>
      <value value="4627315"/>
      <value value="4465674"/>
      <value value="1581973"/>
      <value value="9243450"/>
      <value value="162565"/>
      <value value="930486"/>
      <value value="3574757"/>
      <value value="1722266"/>
      <value value="6969972"/>
      <value value="1207483"/>
      <value value="8429236"/>
      <value value="9353692"/>
      <value value="558933"/>
      <value value="6224037"/>
      <value value="7389713"/>
      <value value="707269"/>
      <value value="643272"/>
      <value value="6222283"/>
      <value value="5094063"/>
      <value value="6084609"/>
      <value value="5368131"/>
      <value value="5198677"/>
      <value value="2150114"/>
      <value value="8323508"/>
      <value value="5968934"/>
      <value value="1084523"/>
      <value value="716357"/>
      <value value="3717019"/>
      <value value="5638660"/>
      <value value="9034942"/>
      <value value="6044522"/>
      <value value="6254370"/>
      <value value="7343495"/>
      <value value="7903518"/>
      <value value="9616277"/>
      <value value="1216250"/>
      <value value="5081872"/>
      <value value="3833113"/>
      <value value="9683954"/>
      <value value="7812599"/>
      <value value="2242191"/>
      <value value="3128372"/>
      <value value="6765406"/>
      <value value="6430526"/>
      <value value="3785524"/>
      <value value="8400432"/>
      <value value="7936255"/>
      <value value="2877574"/>
      <value value="6228430"/>
      <value value="3780224"/>
      <value value="748526"/>
      <value value="4506282"/>
      <value value="2856223"/>
      <value value="8468602"/>
      <value value="8031326"/>
      <value value="5481122"/>
      <value value="2821625"/>
      <value value="1478999"/>
      <value value="6481632"/>
      <value value="3154311"/>
      <value value="5283959"/>
      <value value="165706"/>
      <value value="1538054"/>
      <value value="6402775"/>
      <value value="9393207"/>
      <value value="8084448"/>
      <value value="3222037"/>
      <value value="9632755"/>
      <value value="5543519"/>
      <value value="7694802"/>
      <value value="2197943"/>
      <value value="9416896"/>
      <value value="4567627"/>
      <value value="5048973"/>
      <value value="4824496"/>
      <value value="7601754"/>
      <value value="7035263"/>
      <value value="4700878"/>
      <value value="7329800"/>
      <value value="4415645"/>
      <value value="9718355"/>
      <value value="3642112"/>
      <value value="880757"/>
      <value value="9442883"/>
      <value value="846137"/>
      <value value="7980527"/>
      <value value="9133109"/>
      <value value="9579424"/>
      <value value="15488"/>
      <value value="3919582"/>
      <value value="6858634"/>
      <value value="14191"/>
      <value value="2341739"/>
      <value value="8798589"/>
      <value value="5481085"/>
      <value value="2554009"/>
      <value value="7362998"/>
      <value value="897840"/>
      <value value="3952411"/>
      <value value="4625153"/>
      <value value="5482722"/>
      <value value="7504413"/>
      <value value="1401248"/>
      <value value="8965404"/>
      <value value="3612996"/>
      <value value="103809"/>
      <value value="564281"/>
      <value value="862046"/>
      <value value="431778"/>
      <value value="5641943"/>
      <value value="7896556"/>
      <value value="3543081"/>
      <value value="6049891"/>
      <value value="6870070"/>
      <value value="5997333"/>
      <value value="2697401"/>
      <value value="1996715"/>
      <value value="314742"/>
      <value value="3309188"/>
      <value value="4520723"/>
      <value value="940496"/>
      <value value="7053029"/>
      <value value="5697161"/>
      <value value="114786"/>
      <value value="7899221"/>
      <value value="1805219"/>
      <value value="8823787"/>
      <value value="783746"/>
      <value value="5896636"/>
      <value value="3523507"/>
      <value value="7572687"/>
      <value value="3494553"/>
      <value value="4695558"/>
      <value value="7567167"/>
      <value value="8311846"/>
      <value value="7512491"/>
      <value value="1993362"/>
      <value value="4144815"/>
      <value value="3320167"/>
      <value value="1068778"/>
      <value value="7155607"/>
      <value value="1844465"/>
      <value value="878614"/>
      <value value="3050971"/>
      <value value="731342"/>
      <value value="4898024"/>
      <value value="9135773"/>
      <value value="2233434"/>
      <value value="7781024"/>
      <value value="3031339"/>
      <value value="9273590"/>
      <value value="6143924"/>
      <value value="2988832"/>
      <value value="8056919"/>
      <value value="3062761"/>
      <value value="5374469"/>
      <value value="8741016"/>
      <value value="80784"/>
      <value value="5555286"/>
      <value value="8070105"/>
      <value value="8597816"/>
      <value value="5567635"/>
      <value value="6194144"/>
      <value value="4276422"/>
      <value value="3826422"/>
      <value value="6783237"/>
      <value value="2816339"/>
      <value value="720300"/>
      <value value="5141829"/>
      <value value="8407488"/>
      <value value="3520511"/>
      <value value="3545710"/>
      <value value="4296389"/>
      <value value="7092427"/>
      <value value="7113501"/>
      <value value="3340230"/>
      <value value="2360539"/>
      <value value="9774918"/>
      <value value="6673335"/>
      <value value="2393606"/>
      <value value="5341416"/>
      <value value="5274154"/>
      <value value="884794"/>
      <value value="8082738"/>
      <value value="8043377"/>
      <value value="4582993"/>
      <value value="429273"/>
      <value value="1511027"/>
      <value value="4865806"/>
      <value value="3097206"/>
      <value value="9630843"/>
      <value value="2609301"/>
      <value value="2402826"/>
      <value value="2515951"/>
      <value value="7361759"/>
      <value value="5531947"/>
      <value value="7685484"/>
      <value value="6104397"/>
      <value value="2967240"/>
      <value value="4606180"/>
      <value value="6477648"/>
      <value value="4889201"/>
      <value value="9763457"/>
      <value value="5676629"/>
      <value value="371794"/>
      <value value="6401332"/>
      <value value="8852937"/>
      <value value="2255973"/>
      <value value="5153099"/>
      <value value="9256588"/>
      <value value="9096834"/>
      <value value="4144911"/>
      <value value="940821"/>
      <value value="7731872"/>
      <value value="8998747"/>
      <value value="3167781"/>
      <value value="2294481"/>
      <value value="6521268"/>
      <value value="3137251"/>
      <value value="6547104"/>
      <value value="6970025"/>
      <value value="9055837"/>
      <value value="6036896"/>
      <value value="1909400"/>
      <value value="8764342"/>
      <value value="7421655"/>
      <value value="5715679"/>
      <value value="6565089"/>
      <value value="7176855"/>
      <value value="9090941"/>
      <value value="6046210"/>
      <value value="2561496"/>
      <value value="4554783"/>
      <value value="5774143"/>
      <value value="4802343"/>
      <value value="6114267"/>
      <value value="1716802"/>
      <value value="4719248"/>
      <value value="5827704"/>
      <value value="2749178"/>
      <value value="9321058"/>
      <value value="2144524"/>
      <value value="8091927"/>
      <value value="5041000"/>
      <value value="5359719"/>
      <value value="9792063"/>
      <value value="3447761"/>
      <value value="9584022"/>
      <value value="7675995"/>
      <value value="2351435"/>
      <value value="5480486"/>
      <value value="6748174"/>
      <value value="9236789"/>
      <value value="4896781"/>
      <value value="2669314"/>
      <value value="4044813"/>
      <value value="3282794"/>
      <value value="1816258"/>
      <value value="5590930"/>
      <value value="2722245"/>
      <value value="9414044"/>
      <value value="6270134"/>
      <value value="897941"/>
      <value value="590926"/>
      <value value="8671383"/>
      <value value="4732960"/>
      <value value="8902484"/>
      <value value="1293003"/>
      <value value="7295248"/>
      <value value="656817"/>
      <value value="9862714"/>
      <value value="1565515"/>
      <value value="3049458"/>
      <value value="9948764"/>
      <value value="2595042"/>
      <value value="1797177"/>
      <value value="6629921"/>
      <value value="5514319"/>
      <value value="1458583"/>
      <value value="6412164"/>
      <value value="8580976"/>
      <value value="3755827"/>
      <value value="2979483"/>
      <value value="5542963"/>
      <value value="7729520"/>
      <value value="3622946"/>
      <value value="5158417"/>
      <value value="6040954"/>
      <value value="3946005"/>
      <value value="4451331"/>
      <value value="1395715"/>
      <value value="5773878"/>
      <value value="7031782"/>
      <value value="1227556"/>
      <value value="9615519"/>
      <value value="9548202"/>
      <value value="1540932"/>
      <value value="908028"/>
      <value value="3875805"/>
      <value value="5011977"/>
      <value value="3624813"/>
      <value value="9763006"/>
      <value value="1895157"/>
      <value value="5335678"/>
      <value value="3509650"/>
      <value value="3458713"/>
      <value value="3245357"/>
      <value value="3576263"/>
      <value value="4952134"/>
      <value value="6251525"/>
      <value value="3309574"/>
      <value value="6372241"/>
      <value value="1166737"/>
      <value value="3006477"/>
      <value value="3025113"/>
      <value value="779999"/>
      <value value="9949872"/>
      <value value="8091099"/>
      <value value="7024688"/>
      <value value="6777585"/>
      <value value="1332756"/>
      <value value="5035398"/>
      <value value="1288543"/>
      <value value="7413197"/>
      <value value="9168178"/>
      <value value="2074579"/>
      <value value="9355547"/>
      <value value="7414453"/>
      <value value="1445771"/>
      <value value="2668594"/>
      <value value="1852474"/>
      <value value="8266660"/>
      <value value="1278148"/>
      <value value="7958814"/>
      <value value="3941421"/>
      <value value="7437350"/>
      <value value="7305062"/>
      <value value="3852434"/>
      <value value="487003"/>
      <value value="2931669"/>
      <value value="9402608"/>
      <value value="498654"/>
      <value value="6507018"/>
      <value value="6718347"/>
      <value value="3562922"/>
      <value value="3525643"/>
      <value value="5789027"/>
      <value value="1803952"/>
      <value value="3765759"/>
      <value value="8055365"/>
      <value value="8697077"/>
      <value value="8283319"/>
      <value value="4316473"/>
      <value value="1653737"/>
      <value value="1788556"/>
      <value value="9460529"/>
      <value value="2946823"/>
      <value value="1750906"/>
      <value value="3113511"/>
      <value value="9290274"/>
      <value value="8557180"/>
      <value value="6312627"/>
      <value value="2888240"/>
      <value value="4087738"/>
      <value value="6558729"/>
      <value value="2188460"/>
      <value value="6426115"/>
      <value value="4704873"/>
      <value value="7288251"/>
      <value value="4083063"/>
      <value value="9668791"/>
      <value value="1455338"/>
      <value value="7400074"/>
      <value value="8953344"/>
      <value value="8714984"/>
      <value value="9815796"/>
      <value value="3111316"/>
      <value value="2902360"/>
      <value value="8562865"/>
      <value value="9865507"/>
      <value value="9645186"/>
      <value value="6967847"/>
      <value value="5825932"/>
      <value value="7620951"/>
      <value value="2268979"/>
      <value value="8027488"/>
      <value value="8362468"/>
      <value value="4725720"/>
      <value value="8183708"/>
      <value value="772808"/>
      <value value="6729280"/>
      <value value="9800809"/>
      <value value="4362324"/>
      <value value="3805207"/>
      <value value="5440363"/>
      <value value="2434083"/>
      <value value="6904155"/>
      <value value="1252414"/>
      <value value="9907625"/>
      <value value="8552030"/>
      <value value="3439691"/>
      <value value="7238898"/>
      <value value="710079"/>
      <value value="6972507"/>
      <value value="3402900"/>
      <value value="5270412"/>
      <value value="7907587"/>
      <value value="3378626"/>
      <value value="584193"/>
      <value value="4510029"/>
      <value value="8449859"/>
      <value value="5576130"/>
      <value value="1106320"/>
      <value value="2190132"/>
      <value value="9087670"/>
      <value value="8554330"/>
      <value value="9443299"/>
      <value value="4308302"/>
      <value value="4720201"/>
      <value value="5420863"/>
      <value value="7322645"/>
      <value value="6298725"/>
      <value value="1584867"/>
      <value value="3586650"/>
      <value value="7610331"/>
      <value value="3626741"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;StageCal None&quot;"/>
      <value value="&quot;StageCal_1&quot;"/>
      <value value="&quot;StageCal_1b&quot;"/>
      <value value="&quot;StageCal_2&quot;"/>
      <value value="&quot;StageCal_3&quot;"/>
      <value value="&quot;StageCal_4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_trace_mult">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic_trans">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basestage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_reporting_delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complacency_bound">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_r_reported">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ess_w_risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="essential_workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gather_location_count">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global_transmissability">
      <value value="0.33"/>
      <value value="0.36"/>
      <value value="0.39"/>
      <value value="0.42"/>
      <value value="0.45"/>
      <value value="0.48"/>
      <value value="0.51"/>
      <value value="0.54"/>
      <value value="0.56"/>
      <value value="0.59"/>
      <value value="0.61"/>
      <value value="0.64"/>
      <value value="0.67"/>
      <value value="0.7"/>
      <value value="0.73"/>
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness_period">
      <value value="21.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_period">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_cases">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialscale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="isolation_transmission">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_efficacy_mult">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask_wearing">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskpolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxstage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non_infective_time">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_post_proportion">
      <value value="0.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="os_import_proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptom_prop">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_trigger_loosen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac1_tran_reduct">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_morb_eff">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac2_tran_reduct">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vac_uptake">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_vaceffdays">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_people_avoid">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_time_avoid">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovered_match_rate">
      <value value="0.042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_factor">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale_threshold">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsopen">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary_cases">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfgovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="superspreaders">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symtomatic_present_day">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="2500000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine_available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_frequency">
      <value value="0.1428"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visit_radius">
      <value value="3.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
