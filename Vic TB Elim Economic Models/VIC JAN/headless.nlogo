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
323
62
987
727
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
30.0
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
0.1
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
0.0
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
0.0
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
2.0
1
0
Number

INPUTBOX
204
464
313
525
total_population
2.5E7
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
0.67
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
100.0
1
1
NIL
HORIZONTAL

SLIDER
552
870
749
903
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
1
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
0.0
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
0
1
-1000

SWITCH
1448
322
1582
355
MaskPolicy
MaskPolicy
1
1
-1000

SLIDER
325
907
520
940
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
8.8
1
1
NIL
HORIZONTAL

SLIDER
324
824
522
857
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
6845316.0
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
8.0
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
"AggressElim" "ModerateElim" "TightSupress" "LooseSupress" "None" "Stage 1" "Stage 1b" "Stage 2" "Stage 3" "Stage 4"
4

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
1088
1160
1116
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
325
745
520
778
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
325
785
520
818
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
788
749
821
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
0.0
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
50.0
1
1
NIL
HORIZONTAL

SLIDER
550
909
748
942
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
868
521
901
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
947
519
980
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
747
747
780
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
      <value value="9181870"/>
      <value value="1104316"/>
      <value value="2639496"/>
      <value value="1807198"/>
      <value value="7992956"/>
      <value value="529624"/>
      <value value="351485"/>
      <value value="5215184"/>
      <value value="2865493"/>
      <value value="7995129"/>
      <value value="3020834"/>
      <value value="2000139"/>
      <value value="6621624"/>
      <value value="9771065"/>
      <value value="2269008"/>
      <value value="3940985"/>
      <value value="3130566"/>
      <value value="648319"/>
      <value value="6017050"/>
      <value value="6347095"/>
      <value value="1265381"/>
      <value value="9783610"/>
      <value value="5513807"/>
      <value value="9490287"/>
      <value value="8249735"/>
      <value value="9753308"/>
      <value value="2422253"/>
      <value value="1360467"/>
      <value value="104941"/>
      <value value="4979350"/>
      <value value="6855489"/>
      <value value="8892546"/>
      <value value="4277091"/>
      <value value="5298786"/>
      <value value="1810426"/>
      <value value="7206835"/>
      <value value="9018517"/>
      <value value="1353239"/>
      <value value="7603370"/>
      <value value="9619562"/>
      <value value="2110788"/>
      <value value="7614737"/>
      <value value="1588802"/>
      <value value="6112976"/>
      <value value="4354366"/>
      <value value="1925173"/>
      <value value="5646510"/>
      <value value="4904413"/>
      <value value="8739362"/>
      <value value="9392651"/>
      <value value="6607826"/>
      <value value="5405018"/>
      <value value="2494975"/>
      <value value="6754460"/>
      <value value="5381332"/>
      <value value="9184626"/>
      <value value="3785019"/>
      <value value="7077677"/>
      <value value="9551930"/>
      <value value="6114495"/>
      <value value="5320960"/>
      <value value="8604588"/>
      <value value="7558823"/>
      <value value="5211433"/>
      <value value="1893700"/>
      <value value="8285674"/>
      <value value="9233034"/>
      <value value="1573832"/>
      <value value="7575401"/>
      <value value="9541445"/>
      <value value="9802456"/>
      <value value="8086888"/>
      <value value="4444423"/>
      <value value="4083792"/>
      <value value="6053017"/>
      <value value="8570255"/>
      <value value="6281433"/>
      <value value="5463003"/>
      <value value="4795357"/>
      <value value="6194713"/>
      <value value="761994"/>
      <value value="8723579"/>
      <value value="4908772"/>
      <value value="9123915"/>
      <value value="7537543"/>
      <value value="1909487"/>
      <value value="2673769"/>
      <value value="7016267"/>
      <value value="9606938"/>
      <value value="2832425"/>
      <value value="1178595"/>
      <value value="9729162"/>
      <value value="9911532"/>
      <value value="635266"/>
      <value value="9790449"/>
      <value value="1005637"/>
      <value value="8843523"/>
      <value value="9158322"/>
      <value value="2616074"/>
      <value value="95971"/>
      <value value="464615"/>
      <value value="5845573"/>
      <value value="5089330"/>
      <value value="9007444"/>
      <value value="6925071"/>
      <value value="695088"/>
      <value value="3231400"/>
      <value value="6422675"/>
      <value value="7301447"/>
      <value value="2581523"/>
      <value value="4745728"/>
      <value value="6465429"/>
      <value value="7062813"/>
      <value value="4882884"/>
      <value value="5084109"/>
      <value value="6838890"/>
      <value value="7416278"/>
      <value value="8334236"/>
      <value value="999632"/>
      <value value="5962189"/>
      <value value="9314754"/>
      <value value="7660635"/>
      <value value="458471"/>
      <value value="7136439"/>
      <value value="7883331"/>
      <value value="5536546"/>
      <value value="2426375"/>
      <value value="8007151"/>
      <value value="1182947"/>
      <value value="5155391"/>
      <value value="329118"/>
      <value value="1711723"/>
      <value value="3019520"/>
      <value value="258001"/>
      <value value="3169126"/>
      <value value="2626925"/>
      <value value="8618315"/>
      <value value="5395541"/>
      <value value="2561192"/>
      <value value="4569812"/>
      <value value="6988922"/>
      <value value="4534576"/>
      <value value="1486328"/>
      <value value="2684499"/>
      <value value="1747019"/>
      <value value="3987946"/>
      <value value="7065150"/>
      <value value="3635149"/>
      <value value="5618607"/>
      <value value="6445878"/>
      <value value="7247896"/>
      <value value="344724"/>
      <value value="9927952"/>
      <value value="9732713"/>
      <value value="9777293"/>
      <value value="3445284"/>
      <value value="2097952"/>
      <value value="5615621"/>
      <value value="302511"/>
      <value value="3799782"/>
      <value value="3683780"/>
      <value value="6118254"/>
      <value value="9285523"/>
      <value value="7774736"/>
      <value value="121783"/>
      <value value="8742460"/>
      <value value="1422493"/>
      <value value="3696660"/>
      <value value="6315174"/>
      <value value="2196656"/>
      <value value="1156100"/>
      <value value="7553801"/>
      <value value="9638604"/>
      <value value="6394908"/>
      <value value="7841696"/>
      <value value="3898741"/>
      <value value="9558143"/>
      <value value="2831482"/>
      <value value="7808271"/>
      <value value="852512"/>
      <value value="3123351"/>
      <value value="6448230"/>
      <value value="4005772"/>
      <value value="5936937"/>
      <value value="7766878"/>
      <value value="8790822"/>
      <value value="2123276"/>
      <value value="3438699"/>
      <value value="3909658"/>
      <value value="3125316"/>
      <value value="7476795"/>
      <value value="6610032"/>
      <value value="2819215"/>
      <value value="5624193"/>
      <value value="4395802"/>
      <value value="6307636"/>
      <value value="8556731"/>
      <value value="45446"/>
      <value value="1700981"/>
      <value value="3613267"/>
      <value value="1991414"/>
      <value value="3743769"/>
      <value value="1807067"/>
      <value value="6750589"/>
      <value value="3152700"/>
      <value value="9195422"/>
      <value value="6208189"/>
      <value value="2345421"/>
      <value value="7338277"/>
      <value value="5666883"/>
      <value value="3472328"/>
      <value value="2032307"/>
      <value value="8059050"/>
      <value value="883801"/>
      <value value="9162926"/>
      <value value="9558120"/>
      <value value="2185654"/>
      <value value="5607778"/>
      <value value="9741032"/>
      <value value="2150220"/>
      <value value="8775268"/>
      <value value="6175860"/>
      <value value="1752691"/>
      <value value="2015628"/>
      <value value="2905114"/>
      <value value="9130587"/>
      <value value="7022644"/>
      <value value="8718769"/>
      <value value="7396005"/>
      <value value="9784601"/>
      <value value="6256787"/>
      <value value="5041610"/>
      <value value="4542822"/>
      <value value="8852348"/>
      <value value="6674148"/>
      <value value="8024591"/>
      <value value="8431917"/>
      <value value="921185"/>
      <value value="1622522"/>
      <value value="2688886"/>
      <value value="6612646"/>
      <value value="2678450"/>
      <value value="1575948"/>
      <value value="3448093"/>
      <value value="5754761"/>
      <value value="2477835"/>
      <value value="5125592"/>
      <value value="4410203"/>
      <value value="9477145"/>
      <value value="5214036"/>
      <value value="3382319"/>
      <value value="6453236"/>
      <value value="4132636"/>
      <value value="1040720"/>
      <value value="4698020"/>
      <value value="3925066"/>
      <value value="1919228"/>
      <value value="7595609"/>
      <value value="9583124"/>
      <value value="8927313"/>
      <value value="731454"/>
      <value value="4349116"/>
      <value value="5387722"/>
      <value value="9635233"/>
      <value value="3852361"/>
      <value value="9138188"/>
      <value value="1989945"/>
      <value value="2737115"/>
      <value value="5400070"/>
      <value value="2590449"/>
      <value value="6731472"/>
      <value value="9985167"/>
      <value value="3295669"/>
      <value value="3669654"/>
      <value value="5560118"/>
      <value value="2124062"/>
      <value value="6686445"/>
      <value value="2277673"/>
      <value value="3746746"/>
      <value value="6954965"/>
      <value value="1240782"/>
      <value value="1332779"/>
      <value value="1306357"/>
      <value value="3569609"/>
      <value value="6882718"/>
      <value value="4996539"/>
      <value value="7516019"/>
      <value value="189955"/>
      <value value="6053000"/>
      <value value="3485065"/>
      <value value="8060104"/>
      <value value="49989"/>
      <value value="9124830"/>
      <value value="3306187"/>
      <value value="4737401"/>
      <value value="4466195"/>
      <value value="6442361"/>
      <value value="7302558"/>
      <value value="2151946"/>
      <value value="4837730"/>
      <value value="2632497"/>
      <value value="6735265"/>
      <value value="9090752"/>
      <value value="8593845"/>
      <value value="6724134"/>
      <value value="5328895"/>
      <value value="1856079"/>
      <value value="3509758"/>
      <value value="5083010"/>
      <value value="6859513"/>
      <value value="8516100"/>
      <value value="438819"/>
      <value value="1624383"/>
      <value value="7323693"/>
      <value value="5768730"/>
      <value value="5154190"/>
      <value value="11985"/>
      <value value="557236"/>
      <value value="6287619"/>
      <value value="6160157"/>
      <value value="6957914"/>
      <value value="6226827"/>
      <value value="2165158"/>
      <value value="5446822"/>
      <value value="4167316"/>
      <value value="3168172"/>
      <value value="9721117"/>
      <value value="8145281"/>
      <value value="2848921"/>
      <value value="9485150"/>
      <value value="2005567"/>
      <value value="4813816"/>
      <value value="5589834"/>
      <value value="2250080"/>
      <value value="23644"/>
      <value value="7428947"/>
      <value value="8077203"/>
      <value value="4363571"/>
      <value value="954164"/>
      <value value="1388546"/>
      <value value="3252556"/>
      <value value="2924486"/>
      <value value="7225663"/>
      <value value="5261136"/>
      <value value="8807470"/>
      <value value="786652"/>
      <value value="3842431"/>
      <value value="2117737"/>
      <value value="783365"/>
      <value value="6996802"/>
      <value value="3552270"/>
      <value value="8678874"/>
      <value value="4084584"/>
      <value value="8349602"/>
      <value value="8071602"/>
      <value value="5279429"/>
      <value value="9122199"/>
      <value value="8436065"/>
      <value value="8727015"/>
      <value value="6000938"/>
      <value value="4338824"/>
      <value value="4693588"/>
      <value value="6864163"/>
      <value value="8298579"/>
      <value value="1580636"/>
      <value value="2392581"/>
      <value value="7296177"/>
      <value value="5760717"/>
      <value value="7570122"/>
      <value value="2447261"/>
      <value value="6860430"/>
      <value value="7427955"/>
      <value value="7652495"/>
      <value value="2552263"/>
      <value value="3408594"/>
      <value value="1240081"/>
      <value value="1731454"/>
      <value value="5648660"/>
      <value value="5710695"/>
      <value value="3847857"/>
      <value value="3646053"/>
      <value value="9075084"/>
      <value value="2588914"/>
      <value value="6697307"/>
      <value value="8657505"/>
      <value value="2283018"/>
      <value value="1173347"/>
      <value value="7833222"/>
      <value value="6437843"/>
      <value value="6073554"/>
      <value value="3225144"/>
      <value value="4535919"/>
      <value value="8765061"/>
      <value value="3745027"/>
      <value value="5139729"/>
      <value value="6258308"/>
      <value value="3802342"/>
      <value value="9663097"/>
      <value value="1349231"/>
      <value value="9084815"/>
      <value value="9700678"/>
      <value value="4269159"/>
      <value value="9330054"/>
      <value value="3252460"/>
      <value value="52760"/>
      <value value="92440"/>
      <value value="916509"/>
      <value value="8473113"/>
      <value value="4226116"/>
      <value value="6187099"/>
      <value value="1860503"/>
      <value value="7978930"/>
      <value value="6620687"/>
      <value value="289568"/>
      <value value="6979870"/>
      <value value="904817"/>
      <value value="7632213"/>
      <value value="3070442"/>
      <value value="7465799"/>
      <value value="4440"/>
      <value value="3558475"/>
      <value value="5234620"/>
      <value value="4283256"/>
      <value value="1153676"/>
      <value value="2942616"/>
      <value value="4472351"/>
      <value value="3868454"/>
      <value value="4274553"/>
      <value value="954403"/>
      <value value="4137691"/>
      <value value="2322219"/>
      <value value="4636113"/>
      <value value="8788772"/>
      <value value="7959773"/>
      <value value="9389149"/>
      <value value="7252553"/>
      <value value="7703382"/>
      <value value="3856873"/>
      <value value="1621432"/>
      <value value="5203568"/>
      <value value="121663"/>
      <value value="8902768"/>
      <value value="7493724"/>
      <value value="8442540"/>
      <value value="6079860"/>
      <value value="8680688"/>
      <value value="5629604"/>
      <value value="8748651"/>
      <value value="2484458"/>
      <value value="1775574"/>
      <value value="4102588"/>
      <value value="7076721"/>
      <value value="2231294"/>
      <value value="2403291"/>
      <value value="5862869"/>
      <value value="8655690"/>
      <value value="5395365"/>
      <value value="9695599"/>
      <value value="3004012"/>
      <value value="2974395"/>
      <value value="6499915"/>
      <value value="8092277"/>
      <value value="2269542"/>
      <value value="1329805"/>
      <value value="3865451"/>
      <value value="8256505"/>
      <value value="1154091"/>
      <value value="1222148"/>
      <value value="1570210"/>
      <value value="1787992"/>
      <value value="4727827"/>
      <value value="2572633"/>
      <value value="3066420"/>
      <value value="8875718"/>
      <value value="3057257"/>
      <value value="9607887"/>
      <value value="3906055"/>
      <value value="9714099"/>
      <value value="5101970"/>
      <value value="2019730"/>
      <value value="9270421"/>
      <value value="304674"/>
      <value value="2649864"/>
      <value value="5329643"/>
      <value value="4376067"/>
      <value value="2249448"/>
      <value value="2922154"/>
      <value value="986316"/>
      <value value="3986587"/>
      <value value="7059295"/>
      <value value="8656927"/>
      <value value="4631839"/>
      <value value="3928990"/>
      <value value="4038380"/>
      <value value="2338678"/>
      <value value="3599711"/>
      <value value="1989983"/>
      <value value="3747655"/>
      <value value="6845316"/>
      <value value="9776153"/>
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
      <value value="0.42"/>
      <value value="0.56"/>
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
