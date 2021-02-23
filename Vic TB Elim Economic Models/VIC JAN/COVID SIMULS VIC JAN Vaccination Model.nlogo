;; This version of the model has been speifically designed to estimate issues associated with Victoria's second wave of infections, beginning in early July
;; The intent of the model is for it to be used as a guide for considering differences in potential patterns of infection under various policy futures
;; As with any model, it's results should be interpreted with caution and placed alongside other evidence when interpreting results

extensions [ rngs profiler csv table array matrix ]

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

  real_prior0
  real_prior1
  real_prior2
  real_prior3
  real_prior4
  real_prior5
  real_prior6

  slope_prior0
  slope_prior1
  slope_prior2
  slope_prior3
  slope_prior4
  slope_prior5
  slope_prior6

  slope
  slopeCount
  slopeSum
  slopeAverage

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
1479
54
1612
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

PLOT
2717
99
3122
272
Susceptible, Infected and Recovered - 000's
Days from March 10th
Numbers of people
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Infected Proportion" 1.0 0 -2674135 true "" "plot count simuls with [ color = red ] * (Total_Population / 100 / count Simuls) "
"Susceptible" 1.0 0 -14070903 true "" "plot count simuls with [ color = 85 ] * (Total_Population / 100 / count Simuls)"
"Recovered" 1.0 0 -987046 true "" "plot count simuls with [ color = yellow ] * (Total_Population / 100 / count Simuls)"
"New Infections" 1.0 0 -11221820 true "" "plot count simuls with [ color = red and timenow = Incubation_Period ] * ( Total_Population / 100 / count Simuls )"

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

MONITOR
18
678
167
735
Deaths
Deathcount
0
1
14

MONITOR
2522
29
2677
86
# simuls
count simuls * (Total_Population / population)
0
1
14

MONITOR
2333
1044
2591
1089
Bed Capacity Scaled for Australia at 65,000k
count patches with [ pcolor = white ]
0
1
11

MONITOR
2283
467
2452
524
Total # Infected
cumulativeInfected
0
1
14

SLIDER
1624
253
1803
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

MONITOR
18
740
167
797
% Total Infections
cumulativeInfected / Total_Population * 100
2
1
14

MONITOR
1044
307
1174
352
Case Fatality Rate %
caseFatalityRate * 100
2
1
11

PLOT
1243
218
1445
347
Case Fatality Rate %
NIL
NIL
0.0
10.0
0.0
0.05
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot caseFatalityRate * 100"

SLIDER
1623
57
1805
90
Proportion_People_Avoid
Proportion_People_Avoid
0
100
10.0
.5
1
NIL
HORIZONTAL

SLIDER
1623
92
1806
125
Proportion_Time_Avoid
Proportion_Time_Avoid
0
100
10.0
.5
1
NIL
HORIZONTAL

MONITOR
3242
320
3301
365
R0
mean [ R ] of simuls with [ color = red and timenow = int Illness_Period ]
2
1
11

PLOT
2778
283
3185
405
Estimated count of deceased across age ranges (not scaled)
NIL
NIL
0.0
100.0
0.0
50.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "Histogram [ agerange ] of simuls with [ color = black ] "

PLOT
1839
212
2107
361
Infection Proportional Growth Rate
Time
Growth rate
0.0
300.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 1 [ plot ( InfectionChange ) * 10 ]"

MONITOR
2438
633
2570
678
Infection Growth %
infectionchange
2
1
11

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

MONITOR
1044
254
1216
299
Close contacts per day
AverageContacts
2
1
11

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

PLOT
1838
39
2107
201
Age (black), Vaccinated (green)
NIL
NIL
0.0
100.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ agerange ] of simuls"
"pen-1" 1.0 0 -13840069 true "" "histogram [ agerange ] of simuls with [ vaccinated = 1 ]"
"pen-2" 1.0 0 -2674135 true "" "histogram [ agerange ] of simuls with [ color = red ]"

PLOT
1039
749
1457
988
Active (red) and Total (blue) Infections ICU Beds (black)
NIL
NIL
0.0
10.0
0.0
200.0
true
false
"" "\n"
PENS
"Current Cases" 1.0 1 -7858858 true "" "plot currentInfections "
"Total Infected" 1.0 0 -13345367 true "" "plot cumulativeInfected"
"ICU Beds Required" 1.0 0 -16777216 true "" "plot ICUBedsRequired "

MONITOR
1474
512
1638
561
Reported Inf Today
casesReportedToday
0
1
12

PLOT
1039
489
1456
609
New Infections Per Day
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"New Cases" 1.0 1 -5298144 true "" "plot (Scale_Factor ^ scalephase) * (count simuls with [ color = red and timenow = Case_Reporting_Delay ])"

SLIDER
1669
19
1803
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

MONITOR
3348
847
3423
904
Growth
objFunction
2
1
14

MONITOR
1743
829
1827
874
Red (raw)
count simuls with [ color = red ]
0
1
11

SWITCH
1594
959
1687
992
scale
scale
0
1
-1000

MONITOR
890
13
948
58
NIL
Days
17
1
11

MONITOR
1469
832
1576
881
Scale Exponent
scalePhase
17
1
12

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

MONITOR
1743
929
1823
974
NIL
count simuls
17
1
11

MONITOR
2494
824
2648
873
ICU Beds Needed
ICUBedsRequired
0
1
12

MONITOR
2612
742
2676
791
Links
count links / count simuls with [ color = red ]
0
1
12

MONITOR
2868
418
2982
463
Potential contacts
PotentialContacts
0
1
11

PLOT
2114
42
2403
204
Distribution of Illness pd
NIL
NIL
10.0
40.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ ownIllnessPeriod ] of simuls "

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

PLOT
2417
129
2657
254
Dist_Incubation_Pd
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ ownIncubationPeriod ] of simuls"

MONITOR
1469
618
1534
663
Virulence
mean [ personalvirulence] of simuls
1
1
11

SLIDER
12
448
189
481
Global_Transmissability
Global_Transmissability
0
1
0.26
0.01
1
NIL
HORIZONTAL

SLIDER
1624
214
1802
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
555
914
752
947
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
1484
359
1619
392
tracking
tracking
0
1
-1000

SLIDER
1479
93
1613
126
Mask_Wearing
Mask_Wearing
0
100
35.0
1
1
NIL
HORIZONTAL

SWITCH
1483
282
1618
315
schoolsOpen
schoolsOpen
0
1
-1000

MONITOR
804
13
876
58
Household
mean [ householdunit ] of simuls
1
1
11

PLOT
3100
82
3380
230
Infections by age range
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "Histogram [ agerange ] of simuls with [ color != 85  ]"

MONITOR
2479
754
2595
799
Link Proportion
count links with [ color = blue ] / count links with [ color = red ]
1
1
11

MONITOR
3434
250
3566
295
EW Infection %
EWInfections / 2500
1
1
11

MONITOR
3295
247
3428
292
Student Infections %
studentInfections / 2500
1
1
11

SWITCH
1483
322
1617
355
MaskPolicy
MaskPolicy
0
1
-1000

SLIDER
328
952
523
985
Case_Reporting_Delay
Case_Reporting_Delay
0
20
2.0
1
1
NIL
HORIZONTAL

MONITOR
3198
663
3248
708
>3
sum [ r ] of simuls with [ color != 85  and R = 3]
17
1
11

MONITOR
3145
663
3195
708
=2
sum [ r ] of simuls with [ color != 85  and R = 2]
17
1
11

MONITOR
3249
663
3299
708
=4
sum [ r ] of simuls with [ color != 85  and R = 4]
17
1
11

MONITOR
3299
663
3349
708
>4
sum [ r ] of simuls with [ color != 85  and R > 4]
17
1
11

MONITOR
3199
712
3249
757
C3
count simuls with [ color != 85 and R = 3]
17
1
11

MONITOR
3145
712
3195
757
C2
count simuls with [ color != 85 and R = 2]
17
1
11

MONITOR
3252
713
3302
758
c4
count simuls with [ color != 85 and R = 4]
17
1
11

MONITOR
3302
713
3352
758
C>4
count simuls with [ color != 85 and R > 4 ]
17
1
11

MONITOR
3092
712
3142
757
C1
count simuls with [ color != 85 and R = 1]
17
1
11

MONITOR
3035
712
3085
757
C0
count simuls with [ color != 85 and R = 0]
17
1
11

SLIDER
1624
332
1806
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
1624
369
1807
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

MONITOR
3345
795
3403
840
%>3
count simuls with [ color != 85 and R > 2] / count simuls with [ color != 85 and R > 0 ] * 100
2
1
11

MONITOR
3413
795
3471
840
% R
sum [ R ] of simuls with [ color != 85 and R > 2] / sum [ R ] of simuls with [ color != 85 and R > 0 ] * 100
2
1
11

SLIDER
328
869
526
902
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
1624
294
1804
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

MONITOR
2499
683
2571
728
OS %
( count simuls with [  imported = 1 ] / count simuls with [ color != 85 ]) * 100
2
1
11

SLIDER
1624
178
1801
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

MONITOR
1474
567
1576
612
NIL
currentinfections
17
1
11

MONITOR
1713
449
1838
494
Average Illness time
mean [ timenow ] of simuls with [ color = red ]
1
1
11

MONITOR
2494
889
2599
950
ICU Beds
ICUBedsRequired
0
1
15

CHOOSER
1589
909
1682
954
InitialScale
InitialScale
0 1 2 3 4
0

PLOT
1039
359
1454
483
New cases in last 7, 14, 28 days
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"7" 1.0 0 -16777216 true "" "plot casesinperiod7"
"14" 1.0 0 -7500403 true "" "plot casesinperiod14"
"28" 1.0 0 -2674135 true "" "plot casesinperiod28"

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

PLOT
1040
614
1459
739
Stage (red) and Scale (blue)
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"Stage" 1.0 0 -5298144 true "" "plot stage"
"Scale" 1.0 0 -14454117 true "" "plot scalePhase"

MONITOR
1044
152
1159
197
Cases in period 7
casesinperiod7
0
1
11

MONITOR
1743
879
1825
924
Yellow (raw)
count simuls with [ color = yellow ]
0
1
11

MONITOR
3314
322
3387
367
Time = 1 
count simuls with [ timenow = 2 ]
0
1
11

MONITOR
2494
959
2559
1004
Students
count simuls with [ studentFlag = 1 ]
0
1
11

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
1624
409
1809
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

MONITOR
17
879
106
924
Mean ID Time
meanIDTime
1
1
11

CHOOSER
1665
1215
1804
1260
MaxStage
MaxStage
0 1 2 3 4
4

MONITOR
1239
13
1329
58
Vaccinated %
( count simuls with [ shape = \"person\" ] / 2500 )* 100
2
1
11

SLIDER
13
15
290
48
RAND_SEED
RAND_SEED
0
10000000
3091787.0
1
1
NIL
HORIZONTAL

MONITOR
1339
13
1429
58
Vaccinated
count simuls with [ shape = \"person\" ]
17
1
11

PLOT
1243
64
1438
203
Vaccinated
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count simuls with [ shape = \"person\" ]"

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

MONITOR
1554
619
1642
664
NIL
contact_radius
17
1
11

MONITOR
1479
132
1616
177
NIL
spatial_distance
17
1
11

MONITOR
1479
179
1613
224
NIL
case_isolation
17
1
11

MONITOR
1483
229
1616
274
NIL
quarantine
17
1
11

MONITOR
1382
1163
1540
1208
NIL
Asymptom_Prop
17
1
11

MONITOR
1043
202
1215
247
NIL
Track_and_Trace_Efficiency
17
1
11

MONITOR
1474
667
1531
712
NIL
stage
17
1
11

MONITOR
1713
549
1842
594
Interaction Infectivity
transmission_average
6
1
11

MONITOR
1713
499
1838
544
Virulent Interactions
transmission_count_metric
17
1
11

PLOT
1859
537
2266
711
Potential transmission interactions per day (scaled)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot transmission_count_metric"

TEXTBOX
1493
27
1617
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
"AggressElim" "ModerateElim" "TightSupress" "LooseSupress" "None" "Stage 1" "Stage 1b" "Stage 2" "Stage 3" "Stage 4" "StageCal None" "StageCal Isolate" "StageCal_1" "StageCal_1b" "StageCal_2" "StageCal_3" "StageCal_4"
16

SLIDER
1589
834
1726
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
1589
872
1727
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

MONITOR
1469
889
1577
934
Person per Simul
(Scale_Factor ^ scalephase)
17
1
11

MONITOR
1469
943
1579
988
People in Model
(Population * Scale_Factor ^ scalephase)
17
1
11

PLOT
1859
717
2324
875
Case Tracking (scaled)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Tracked" 1.0 0 -16777216 true "" "plot count simuls with [ color = red and tracked = 1 ] * Scale_Factor ^ scalephase"
"Total" 1.0 0 -7500403 true "" "plot count simuls with [ color = red ] * Scale_Factor ^ scalephase"
"Reported" 1.0 0 -2674135 true "" "plot count simuls with [ color = red and tracked = 1 and caseReportTime <= ticks] * Scale_Factor ^ scalephase"
"Qr'tine" 1.0 0 -13840069 true "" "plot count simuls with [ color = red and inQuarantine = 1] * Scale_Factor ^ scalephase"

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
328
789
523
822
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
328
829
523
862
Asymptom_Trace_Mult
Asymptom_Trace_Mult
0
1
0.33
0.01
1
NIL
HORIZONTAL

PLOT
1859
384
2268
534
Average Interaction Infectivity
NIL
NIL
0.0
10.0
0.0
0.2
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot transmission_average"

MONITOR
1709
598
1839
643
Expected New Cases
transmission_count_metric * transmission_average
6
1
11

PLOT
1863
879
2327
1027
States (raw)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Isolating" 1.0 0 -12345184 true "" "plot count simuls with [color = cyan and isolating = 1]"
"Infected" 1.0 0 -2674135 true "" "plot count simuls with [color = red]"
"Tracked" 1.0 0 -5825686 true "" "plot count simuls with [color = red and tracked = 1]"
"Qr'tine" 1.0 0 -13840069 true "" "plot count simuls with [color = red and inQuarantine = 1]"
"Recovered" 1.0 0 -1184463 true "" "plot count simuls with [color = yellow]"

SLIDER
555
832
752
865
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
1624
134
1806
167
Complacency_Bound
Complacency_Bound
0
100
5.0
1
1
NIL
HORIZONTAL

PLOT
2419
264
2698
384
Distribution of currentVirulence
NIL
NIL
0.0
1.2
0.0
1.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [ currentVirulence ] of simuls with [ color = red ]"

MONITOR
1713
648
1843
693
Real New Cases
new_case_real
17
1
11

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
1044
13
1217
46
End_Day
End_Day
-1
365
91.0
1
1
NIL
HORIZONTAL

SLIDER
553
954
751
987
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
328
912
525
945
Non_Infective_Time
Non_Infective_Time
0
4
2.0
1
1
NIL
HORIZONTAL

MONITOR
1474
463
1631
508
NIL
totalOverseasIncursions
17
1
11

PLOT
2117
213
2407
362
OverseasIncursions
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Incursions" 1.0 0 -16777216 true "" "plot totalOverseasIncursions"
"People" 1.0 0 -7500403 true "" "plot global_incursionArrivals"
"% Chance" 1.0 0 -2674135 true "" "plot global_incursionRisk * 100"

SWITCH
1469
739
1573
772
track_R
track_R
0
1
-1000

PLOT
1598
700
1828
820
Average R (black), New R (grey)
NIL
NIL
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ifelse totalEndCount > 0 [plot totalEndR / totalEndCount][plot 0]"
"pen-1" 1.0 0 -7500403 true "" "plot endR_mean_metric"

MONITOR
1469
779
1577
824
NIL
average_R
6
1
11

PLOT
2279
464
2558
624
Cohorts and infections
NIL
NIL
0.0
37.0
0.0
50.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ cohortIndex ] of simuls"
"pen-1" 1.0 0 -5298144 true "" "histogram [ cohortIndex ] of simuls with [ color = red ]"

MONITOR
18
618
168
675
Total Infected
cumulativeInfected
17
1
14

SLIDER
328
992
523
1025
Symtomatic_Present_Day
Symtomatic_Present_Day
-1
20
6.0
1
1
NIL
HORIZONTAL

MONITOR
18
808
173
865
% Living Recovered
recoverProportion * 100
2
1
14

SLIDER
555
792
750
825
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

MONITOR
1484
398
1618
443
NIL
policyTriggerScale
17
1
11

SLIDER
1044
53
1217
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

MONITOR
1044
99
1216
144
NIL
totalEndCount
17
1
11

MONITOR
917
752
1022
797
slopeAverage %
slopeAverage * 100
3
1
11

PLOT
769
808
1026
958
slope %
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot slopeAverage * 100"
"pen-1" 1.0 0 -7500403 true "" "plot slope * 100"
"pen-2" 1.0 0 -2674135 true "" "plot slope_prior0 / 20"

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
      <value value="7718895"/>
      <value value="3112539"/>
      <value value="411040"/>
      <value value="7911440"/>
      <value value="3708070"/>
      <value value="3613568"/>
      <value value="4735114"/>
      <value value="4125068"/>
      <value value="2073961"/>
      <value value="8345203"/>
      <value value="7659774"/>
      <value value="8532508"/>
      <value value="7597641"/>
      <value value="3292367"/>
      <value value="8823363"/>
      <value value="7007207"/>
      <value value="2243958"/>
      <value value="8469033"/>
      <value value="382536"/>
      <value value="584797"/>
      <value value="6497435"/>
      <value value="10435"/>
      <value value="962209"/>
      <value value="3358343"/>
      <value value="6778353"/>
      <value value="2192245"/>
      <value value="6650992"/>
      <value value="7216142"/>
      <value value="7969284"/>
      <value value="5930886"/>
      <value value="4875286"/>
      <value value="1477132"/>
      <value value="8263800"/>
      <value value="7542875"/>
      <value value="3212083"/>
      <value value="3214868"/>
      <value value="915786"/>
      <value value="4371556"/>
      <value value="6712216"/>
      <value value="8056765"/>
      <value value="9089918"/>
      <value value="6892276"/>
      <value value="2429792"/>
      <value value="946450"/>
      <value value="6896983"/>
      <value value="7613132"/>
      <value value="9641468"/>
      <value value="8880403"/>
      <value value="5950572"/>
      <value value="1441785"/>
      <value value="8716116"/>
      <value value="6654692"/>
      <value value="9388202"/>
      <value value="9855400"/>
      <value value="5127863"/>
      <value value="4302572"/>
      <value value="477617"/>
      <value value="2336423"/>
      <value value="6304228"/>
      <value value="8516486"/>
      <value value="4338740"/>
      <value value="4731645"/>
      <value value="8861816"/>
      <value value="8681955"/>
      <value value="5538102"/>
      <value value="5407364"/>
      <value value="2986003"/>
      <value value="3750305"/>
      <value value="6915813"/>
      <value value="1690304"/>
      <value value="8463886"/>
      <value value="9341047"/>
      <value value="5977227"/>
      <value value="5595142"/>
      <value value="6327214"/>
      <value value="5813880"/>
      <value value="5986721"/>
      <value value="9375879"/>
      <value value="6687031"/>
      <value value="2842618"/>
      <value value="3585525"/>
      <value value="7672003"/>
      <value value="7990283"/>
      <value value="174090"/>
      <value value="2244464"/>
      <value value="1475007"/>
      <value value="5027585"/>
      <value value="3895170"/>
      <value value="4559631"/>
      <value value="9934717"/>
      <value value="5318488"/>
      <value value="6303638"/>
      <value value="9827540"/>
      <value value="3980107"/>
      <value value="3525963"/>
      <value value="383687"/>
      <value value="652213"/>
      <value value="9429860"/>
      <value value="4312940"/>
      <value value="4258827"/>
      <value value="3544804"/>
      <value value="8146670"/>
      <value value="4645139"/>
      <value value="5513703"/>
      <value value="1172114"/>
      <value value="7869790"/>
      <value value="5471278"/>
      <value value="5323059"/>
      <value value="5206443"/>
      <value value="970686"/>
      <value value="6996958"/>
      <value value="2385006"/>
      <value value="89661"/>
      <value value="9316935"/>
      <value value="3715674"/>
      <value value="6069555"/>
      <value value="4818989"/>
      <value value="8862648"/>
      <value value="5062216"/>
      <value value="6787825"/>
      <value value="8864700"/>
      <value value="4448603"/>
      <value value="9594504"/>
      <value value="8050937"/>
      <value value="2561158"/>
      <value value="5833736"/>
      <value value="4210927"/>
      <value value="568003"/>
      <value value="8260848"/>
      <value value="8755787"/>
      <value value="7926623"/>
      <value value="4608681"/>
      <value value="9088959"/>
      <value value="7087616"/>
      <value value="8786912"/>
      <value value="6618381"/>
      <value value="5059497"/>
      <value value="9943820"/>
      <value value="2606855"/>
      <value value="9457217"/>
      <value value="8002040"/>
      <value value="8990469"/>
      <value value="3989385"/>
      <value value="5418508"/>
      <value value="5620060"/>
      <value value="9193551"/>
      <value value="1317120"/>
      <value value="5097064"/>
      <value value="3686216"/>
      <value value="1033520"/>
      <value value="6525578"/>
      <value value="6207983"/>
      <value value="5096353"/>
      <value value="5662456"/>
      <value value="6162131"/>
      <value value="9855693"/>
      <value value="6341593"/>
      <value value="4269269"/>
      <value value="1248520"/>
      <value value="9478426"/>
      <value value="3336952"/>
      <value value="9242986"/>
      <value value="4533431"/>
      <value value="3186957"/>
      <value value="6864239"/>
      <value value="8659564"/>
      <value value="9651831"/>
      <value value="2611925"/>
      <value value="5667549"/>
      <value value="3778800"/>
      <value value="7459892"/>
      <value value="2926572"/>
      <value value="1663125"/>
      <value value="4054141"/>
      <value value="9752135"/>
      <value value="425194"/>
      <value value="3843713"/>
      <value value="2776391"/>
      <value value="4609036"/>
      <value value="6147680"/>
      <value value="2292558"/>
      <value value="8156934"/>
      <value value="1388532"/>
      <value value="7333861"/>
      <value value="4299493"/>
      <value value="4406344"/>
      <value value="1252160"/>
      <value value="2736105"/>
      <value value="7576665"/>
      <value value="3702498"/>
      <value value="5928506"/>
      <value value="8644357"/>
      <value value="9996117"/>
      <value value="6770897"/>
      <value value="7853724"/>
      <value value="5217561"/>
      <value value="2058236"/>
      <value value="4351514"/>
      <value value="1646637"/>
      <value value="4095530"/>
      <value value="4006351"/>
      <value value="8683574"/>
      <value value="5003621"/>
      <value value="7836165"/>
      <value value="663394"/>
      <value value="2429868"/>
      <value value="7215841"/>
      <value value="5770794"/>
      <value value="5886251"/>
      <value value="5280580"/>
      <value value="2275830"/>
      <value value="8258399"/>
      <value value="9957552"/>
      <value value="3803381"/>
      <value value="1496563"/>
      <value value="2211342"/>
      <value value="6197327"/>
      <value value="8114890"/>
      <value value="9624900"/>
      <value value="7336065"/>
      <value value="7130382"/>
      <value value="4141777"/>
      <value value="8553573"/>
      <value value="4502231"/>
      <value value="3602857"/>
      <value value="809646"/>
      <value value="1176587"/>
      <value value="8933653"/>
      <value value="9326259"/>
      <value value="7858929"/>
      <value value="1065112"/>
      <value value="9896952"/>
      <value value="6122655"/>
      <value value="6602489"/>
      <value value="1609099"/>
      <value value="7118412"/>
      <value value="5459373"/>
      <value value="7075366"/>
      <value value="4657372"/>
      <value value="5228206"/>
      <value value="8614928"/>
      <value value="542375"/>
      <value value="4896620"/>
      <value value="5315509"/>
      <value value="6220268"/>
      <value value="6698069"/>
      <value value="1072271"/>
      <value value="1203810"/>
      <value value="416838"/>
      <value value="8714670"/>
      <value value="9795767"/>
      <value value="3896500"/>
      <value value="4851108"/>
      <value value="5650205"/>
      <value value="5214336"/>
      <value value="4201607"/>
      <value value="9068150"/>
      <value value="2066692"/>
      <value value="9374258"/>
      <value value="2004832"/>
      <value value="3468483"/>
      <value value="2656338"/>
      <value value="858824"/>
      <value value="8534672"/>
      <value value="7591518"/>
      <value value="5333737"/>
      <value value="3052065"/>
      <value value="4539439"/>
      <value value="9833406"/>
      <value value="1740349"/>
      <value value="221098"/>
      <value value="7966232"/>
      <value value="9798589"/>
      <value value="350550"/>
      <value value="491829"/>
      <value value="6948048"/>
      <value value="4848140"/>
      <value value="8174815"/>
      <value value="3517045"/>
      <value value="7314699"/>
      <value value="8376470"/>
      <value value="3912926"/>
      <value value="8759426"/>
      <value value="7499340"/>
      <value value="880163"/>
      <value value="1993715"/>
      <value value="5009910"/>
      <value value="6754018"/>
      <value value="7378822"/>
      <value value="6858698"/>
      <value value="8615733"/>
      <value value="8676950"/>
      <value value="3625479"/>
      <value value="6094778"/>
      <value value="1101176"/>
      <value value="2560571"/>
      <value value="4536605"/>
      <value value="2035230"/>
      <value value="7464062"/>
      <value value="1131168"/>
      <value value="640309"/>
      <value value="8640917"/>
      <value value="3577173"/>
      <value value="6314727"/>
      <value value="9264064"/>
      <value value="3060887"/>
      <value value="3333816"/>
      <value value="5105921"/>
      <value value="2991088"/>
      <value value="4853970"/>
      <value value="4241127"/>
      <value value="5384044"/>
      <value value="9025786"/>
      <value value="4362436"/>
      <value value="4315457"/>
      <value value="2788614"/>
      <value value="7217633"/>
      <value value="1013893"/>
      <value value="5618857"/>
      <value value="3253852"/>
      <value value="7062211"/>
      <value value="3716634"/>
      <value value="4763047"/>
      <value value="8045973"/>
      <value value="1670362"/>
      <value value="2352779"/>
      <value value="9252128"/>
      <value value="6713408"/>
      <value value="6779086"/>
      <value value="4194390"/>
      <value value="3696111"/>
      <value value="9740577"/>
      <value value="5862257"/>
      <value value="4222500"/>
      <value value="5489343"/>
      <value value="109093"/>
      <value value="3674936"/>
      <value value="8550485"/>
      <value value="1167667"/>
      <value value="5576411"/>
      <value value="6890195"/>
      <value value="6313041"/>
      <value value="8022848"/>
      <value value="7578813"/>
      <value value="5243461"/>
      <value value="5534350"/>
      <value value="3210127"/>
      <value value="1897260"/>
      <value value="2199634"/>
      <value value="1435209"/>
      <value value="5942225"/>
      <value value="3360765"/>
      <value value="4220830"/>
      <value value="8970736"/>
      <value value="3057519"/>
      <value value="7634331"/>
      <value value="7690545"/>
      <value value="4824365"/>
      <value value="3084905"/>
      <value value="2363801"/>
      <value value="6997516"/>
      <value value="1407182"/>
      <value value="1704258"/>
      <value value="8378020"/>
      <value value="3469797"/>
      <value value="5435050"/>
      <value value="5071849"/>
      <value value="2942268"/>
      <value value="6907258"/>
      <value value="9511083"/>
      <value value="9511336"/>
      <value value="2946942"/>
      <value value="6505874"/>
      <value value="7502407"/>
      <value value="9324702"/>
      <value value="3595489"/>
      <value value="5978444"/>
      <value value="1705183"/>
      <value value="4089825"/>
      <value value="1485596"/>
      <value value="9792958"/>
      <value value="3567745"/>
      <value value="1300129"/>
      <value value="8298155"/>
      <value value="8712458"/>
      <value value="792944"/>
      <value value="1081933"/>
      <value value="67705"/>
      <value value="7252477"/>
      <value value="9440854"/>
      <value value="8289789"/>
      <value value="4093277"/>
      <value value="707808"/>
      <value value="8810415"/>
      <value value="7956636"/>
      <value value="4044689"/>
      <value value="7561389"/>
      <value value="7869199"/>
      <value value="125712"/>
      <value value="8886516"/>
      <value value="9444961"/>
      <value value="1616586"/>
      <value value="1419282"/>
      <value value="1827031"/>
      <value value="3539152"/>
      <value value="2319226"/>
      <value value="4789420"/>
      <value value="3843355"/>
      <value value="4257091"/>
      <value value="6113880"/>
      <value value="4745077"/>
      <value value="9768063"/>
      <value value="3691579"/>
      <value value="4359387"/>
      <value value="2497331"/>
      <value value="5821207"/>
      <value value="8537310"/>
      <value value="1076526"/>
      <value value="542199"/>
      <value value="5726017"/>
      <value value="1501543"/>
      <value value="4850323"/>
      <value value="3728454"/>
      <value value="6025589"/>
      <value value="4948762"/>
      <value value="4696926"/>
      <value value="1211954"/>
      <value value="2522501"/>
      <value value="6795657"/>
      <value value="7727078"/>
      <value value="6568277"/>
      <value value="7462701"/>
      <value value="4921437"/>
      <value value="2323492"/>
      <value value="5610271"/>
      <value value="34178"/>
      <value value="4244663"/>
      <value value="422621"/>
      <value value="1735720"/>
      <value value="3317899"/>
      <value value="5254414"/>
      <value value="3997231"/>
      <value value="7161865"/>
      <value value="9951599"/>
      <value value="4646764"/>
      <value value="6151281"/>
      <value value="4949183"/>
      <value value="1919060"/>
      <value value="6063516"/>
      <value value="9150896"/>
      <value value="2697838"/>
      <value value="5345125"/>
      <value value="9388111"/>
      <value value="8552983"/>
      <value value="8874509"/>
      <value value="1987059"/>
      <value value="9535554"/>
      <value value="8113291"/>
      <value value="3136616"/>
      <value value="3810622"/>
      <value value="2259676"/>
      <value value="2478345"/>
      <value value="7605460"/>
      <value value="4242077"/>
      <value value="9943807"/>
      <value value="5932535"/>
      <value value="9009285"/>
      <value value="7058747"/>
      <value value="5234658"/>
      <value value="1218311"/>
      <value value="7415917"/>
      <value value="3022133"/>
      <value value="1062575"/>
      <value value="9888410"/>
      <value value="2270131"/>
      <value value="8850097"/>
      <value value="4171919"/>
      <value value="756968"/>
      <value value="2305998"/>
      <value value="2166187"/>
      <value value="1056588"/>
      <value value="6051798"/>
      <value value="9090307"/>
      <value value="4948796"/>
      <value value="5833178"/>
      <value value="4857629"/>
      <value value="6369304"/>
      <value value="6849548"/>
      <value value="6102075"/>
      <value value="3406009"/>
      <value value="7248543"/>
      <value value="1030188"/>
      <value value="6756052"/>
      <value value="5373150"/>
      <value value="696827"/>
      <value value="4435736"/>
      <value value="9072009"/>
      <value value="9161840"/>
      <value value="3255284"/>
      <value value="2324777"/>
      <value value="7602308"/>
      <value value="7387875"/>
      <value value="6103004"/>
      <value value="7390579"/>
      <value value="1036651"/>
      <value value="1084489"/>
      <value value="4340894"/>
      <value value="1749289"/>
      <value value="568020"/>
      <value value="9816238"/>
      <value value="5508438"/>
      <value value="6158255"/>
      <value value="8444954"/>
      <value value="2824281"/>
      <value value="955304"/>
      <value value="7041501"/>
      <value value="251082"/>
      <value value="1254883"/>
      <value value="1681590"/>
      <value value="8240758"/>
      <value value="2128837"/>
      <value value="3428101"/>
      <value value="3534609"/>
      <value value="8129916"/>
      <value value="2433096"/>
      <value value="9601099"/>
      <value value="7099627"/>
      <value value="6701507"/>
      <value value="6495828"/>
      <value value="7196347"/>
      <value value="3487414"/>
      <value value="7010697"/>
      <value value="6634718"/>
      <value value="9857677"/>
      <value value="2395440"/>
      <value value="4614120"/>
      <value value="3521902"/>
      <value value="1504826"/>
      <value value="7708349"/>
      <value value="1531172"/>
      <value value="9442536"/>
      <value value="6328653"/>
      <value value="4356006"/>
      <value value="784268"/>
      <value value="3071663"/>
      <value value="7739203"/>
      <value value="793246"/>
      <value value="8226131"/>
      <value value="7872438"/>
      <value value="6895725"/>
      <value value="5878033"/>
      <value value="1843237"/>
      <value value="5587230"/>
      <value value="7527127"/>
      <value value="1721774"/>
      <value value="6781478"/>
      <value value="2220419"/>
      <value value="1316550"/>
      <value value="6348168"/>
      <value value="1424366"/>
      <value value="5532793"/>
      <value value="2156623"/>
      <value value="321103"/>
      <value value="4046481"/>
      <value value="4758439"/>
      <value value="7759050"/>
      <value value="4568033"/>
      <value value="8194321"/>
      <value value="452171"/>
      <value value="5179956"/>
      <value value="3676386"/>
      <value value="5298218"/>
      <value value="1466762"/>
      <value value="3692575"/>
      <value value="542036"/>
      <value value="4798611"/>
      <value value="8429047"/>
      <value value="7850650"/>
      <value value="9644853"/>
      <value value="3389691"/>
      <value value="2764448"/>
      <value value="7761537"/>
      <value value="1209788"/>
      <value value="3398803"/>
      <value value="2750582"/>
      <value value="3467460"/>
      <value value="8196077"/>
      <value value="1942761"/>
      <value value="7952391"/>
      <value value="2746920"/>
      <value value="1893380"/>
      <value value="8904502"/>
      <value value="2825759"/>
      <value value="1865911"/>
      <value value="5219353"/>
      <value value="575709"/>
      <value value="3760686"/>
      <value value="5959355"/>
      <value value="4033915"/>
      <value value="4165261"/>
      <value value="6816498"/>
      <value value="3747405"/>
      <value value="5533667"/>
      <value value="371720"/>
      <value value="3138482"/>
      <value value="6500661"/>
      <value value="3479987"/>
      <value value="1033298"/>
      <value value="3609110"/>
      <value value="8790688"/>
      <value value="3838643"/>
      <value value="1654141"/>
      <value value="7881878"/>
      <value value="59587"/>
      <value value="4869356"/>
      <value value="2581557"/>
      <value value="2185351"/>
      <value value="5639448"/>
      <value value="3952778"/>
      <value value="5087461"/>
      <value value="1744549"/>
      <value value="1924833"/>
      <value value="5894982"/>
      <value value="4536573"/>
      <value value="5575905"/>
      <value value="4252052"/>
      <value value="5313763"/>
      <value value="6103579"/>
      <value value="4150886"/>
      <value value="5576063"/>
      <value value="9504504"/>
      <value value="7160960"/>
      <value value="3957602"/>
      <value value="6786098"/>
      <value value="2472044"/>
      <value value="8639938"/>
      <value value="5418567"/>
      <value value="1172382"/>
      <value value="8656860"/>
      <value value="841488"/>
      <value value="8205214"/>
      <value value="1267761"/>
      <value value="6145447"/>
      <value value="2199919"/>
      <value value="5280856"/>
      <value value="9072835"/>
      <value value="510756"/>
      <value value="5098617"/>
      <value value="6789222"/>
      <value value="2356388"/>
      <value value="9086281"/>
      <value value="8175415"/>
      <value value="2900793"/>
      <value value="6591306"/>
      <value value="7689478"/>
      <value value="7350607"/>
      <value value="6443327"/>
      <value value="704376"/>
      <value value="9052422"/>
      <value value="7775265"/>
      <value value="8884616"/>
      <value value="6286366"/>
      <value value="144851"/>
      <value value="9570201"/>
      <value value="7481267"/>
      <value value="5108992"/>
      <value value="3679474"/>
      <value value="9143627"/>
      <value value="9998951"/>
      <value value="4888623"/>
      <value value="5397076"/>
      <value value="7439676"/>
      <value value="8610507"/>
      <value value="1863531"/>
      <value value="1323016"/>
      <value value="4521465"/>
      <value value="4263936"/>
      <value value="7661577"/>
      <value value="2075444"/>
      <value value="8822503"/>
      <value value="9662316"/>
      <value value="2973335"/>
      <value value="7071415"/>
      <value value="8159649"/>
      <value value="9283375"/>
      <value value="1131087"/>
      <value value="9303439"/>
      <value value="8104401"/>
      <value value="9743829"/>
      <value value="8306635"/>
      <value value="5731223"/>
      <value value="4121385"/>
      <value value="2869347"/>
      <value value="3920902"/>
      <value value="6167083"/>
      <value value="7419525"/>
      <value value="5908477"/>
      <value value="6064562"/>
      <value value="6424885"/>
      <value value="6969564"/>
      <value value="3927848"/>
      <value value="2358372"/>
      <value value="3251248"/>
      <value value="1751034"/>
      <value value="8468127"/>
      <value value="8353018"/>
      <value value="951349"/>
      <value value="8542770"/>
      <value value="6194462"/>
      <value value="4018656"/>
      <value value="7065348"/>
      <value value="3097042"/>
      <value value="4195395"/>
      <value value="5250943"/>
      <value value="7240650"/>
      <value value="9608548"/>
      <value value="5108265"/>
      <value value="4593450"/>
      <value value="5425759"/>
      <value value="3676105"/>
      <value value="1692371"/>
      <value value="1706692"/>
      <value value="1757632"/>
      <value value="1092206"/>
      <value value="8437560"/>
      <value value="3961722"/>
      <value value="1975323"/>
      <value value="9185287"/>
      <value value="2335293"/>
      <value value="5763230"/>
      <value value="8788200"/>
      <value value="3497859"/>
      <value value="9512182"/>
      <value value="8112497"/>
      <value value="4892056"/>
      <value value="4585252"/>
      <value value="606525"/>
      <value value="5318331"/>
      <value value="6177637"/>
      <value value="8993398"/>
      <value value="3020530"/>
      <value value="3816854"/>
      <value value="5490402"/>
      <value value="3641237"/>
      <value value="7580938"/>
      <value value="5825082"/>
      <value value="6926254"/>
      <value value="2174499"/>
      <value value="6253317"/>
      <value value="8119953"/>
      <value value="6451779"/>
      <value value="6570102"/>
      <value value="1504805"/>
      <value value="5223626"/>
      <value value="2235675"/>
      <value value="3813760"/>
      <value value="6440646"/>
      <value value="3061320"/>
      <value value="5698975"/>
      <value value="6745788"/>
      <value value="9896101"/>
      <value value="7185109"/>
      <value value="1127408"/>
      <value value="7284052"/>
      <value value="2706810"/>
      <value value="4217887"/>
      <value value="7958121"/>
      <value value="537616"/>
      <value value="8762620"/>
      <value value="3687811"/>
      <value value="5269781"/>
      <value value="7582593"/>
      <value value="9611906"/>
      <value value="1196910"/>
      <value value="1667805"/>
      <value value="4475446"/>
      <value value="9849161"/>
      <value value="7272361"/>
      <value value="2613494"/>
      <value value="4529989"/>
      <value value="3051819"/>
      <value value="3320541"/>
      <value value="3801624"/>
      <value value="1993259"/>
      <value value="598272"/>
      <value value="6551119"/>
      <value value="3631792"/>
      <value value="9552753"/>
      <value value="3309648"/>
      <value value="2038147"/>
      <value value="3679627"/>
      <value value="8911977"/>
      <value value="2081431"/>
      <value value="5467578"/>
      <value value="7263638"/>
      <value value="3764122"/>
      <value value="8585034"/>
      <value value="5689008"/>
      <value value="7553471"/>
      <value value="8592865"/>
      <value value="6630288"/>
      <value value="3252194"/>
      <value value="8272977"/>
      <value value="8910981"/>
      <value value="3092377"/>
      <value value="7643090"/>
      <value value="4750985"/>
      <value value="3140520"/>
      <value value="6814768"/>
      <value value="4551104"/>
      <value value="9755734"/>
      <value value="6466784"/>
      <value value="6872930"/>
      <value value="2957058"/>
      <value value="4555390"/>
      <value value="6873632"/>
      <value value="518204"/>
      <value value="4727494"/>
      <value value="5754016"/>
      <value value="1728199"/>
      <value value="6771342"/>
      <value value="439179"/>
      <value value="4388049"/>
      <value value="1929255"/>
      <value value="1649138"/>
      <value value="2962770"/>
      <value value="1111983"/>
      <value value="2703915"/>
      <value value="7494705"/>
      <value value="4517580"/>
      <value value="9754736"/>
      <value value="6707959"/>
      <value value="6713379"/>
      <value value="5215926"/>
      <value value="5112795"/>
      <value value="5416889"/>
      <value value="558875"/>
      <value value="1108435"/>
      <value value="6098286"/>
      <value value="8691869"/>
      <value value="5473397"/>
      <value value="6503758"/>
      <value value="6457319"/>
      <value value="5745239"/>
      <value value="5342009"/>
      <value value="208641"/>
      <value value="9583692"/>
      <value value="8857210"/>
      <value value="2918482"/>
      <value value="9093732"/>
      <value value="7697365"/>
      <value value="4595666"/>
      <value value="8088404"/>
      <value value="7374522"/>
      <value value="8002833"/>
      <value value="4623441"/>
      <value value="3060095"/>
      <value value="6672145"/>
      <value value="6148617"/>
      <value value="65226"/>
      <value value="8339910"/>
      <value value="174343"/>
      <value value="1779694"/>
      <value value="7121344"/>
      <value value="8945732"/>
      <value value="2731203"/>
      <value value="798810"/>
      <value value="3055577"/>
      <value value="994794"/>
      <value value="4971717"/>
      <value value="1926233"/>
      <value value="5294506"/>
      <value value="8451221"/>
      <value value="7657904"/>
      <value value="435498"/>
      <value value="4522413"/>
      <value value="7928346"/>
      <value value="7553806"/>
      <value value="8590064"/>
      <value value="1290326"/>
      <value value="2713825"/>
      <value value="5793048"/>
      <value value="9249222"/>
      <value value="4690394"/>
      <value value="5868023"/>
      <value value="6853404"/>
      <value value="7999967"/>
      <value value="4532559"/>
      <value value="8454654"/>
      <value value="8978119"/>
      <value value="6887693"/>
      <value value="8704741"/>
      <value value="7002241"/>
      <value value="2322006"/>
      <value value="1057963"/>
      <value value="7293172"/>
      <value value="7291218"/>
      <value value="4462904"/>
      <value value="1797012"/>
      <value value="4969353"/>
      <value value="5103119"/>
      <value value="2224372"/>
      <value value="3382301"/>
      <value value="9993664"/>
      <value value="4952808"/>
      <value value="7939298"/>
      <value value="9642376"/>
      <value value="7485418"/>
      <value value="8220757"/>
      <value value="5092254"/>
      <value value="7084855"/>
      <value value="7148286"/>
      <value value="2492794"/>
      <value value="4872811"/>
      <value value="6099068"/>
      <value value="3664363"/>
      <value value="9097628"/>
      <value value="177750"/>
      <value value="6594114"/>
      <value value="592890"/>
      <value value="915257"/>
      <value value="9806137"/>
      <value value="2123792"/>
      <value value="5534657"/>
      <value value="4204191"/>
      <value value="6938743"/>
      <value value="2817075"/>
      <value value="6438732"/>
      <value value="2396842"/>
      <value value="1833068"/>
      <value value="3650822"/>
      <value value="6430924"/>
      <value value="3135325"/>
      <value value="5264773"/>
      <value value="1030343"/>
      <value value="9935608"/>
      <value value="7364853"/>
      <value value="8645470"/>
      <value value="3255478"/>
      <value value="4549086"/>
      <value value="5278805"/>
      <value value="7899613"/>
      <value value="1465774"/>
      <value value="4293676"/>
      <value value="6543204"/>
      <value value="6618805"/>
      <value value="7258239"/>
      <value value="7522583"/>
      <value value="879432"/>
      <value value="4398567"/>
      <value value="3825834"/>
      <value value="4138324"/>
      <value value="3990944"/>
      <value value="5366360"/>
      <value value="3629947"/>
      <value value="3430145"/>
      <value value="6468398"/>
      <value value="3523334"/>
      <value value="1652853"/>
      <value value="1379428"/>
      <value value="833897"/>
      <value value="922268"/>
      <value value="6402730"/>
      <value value="6813305"/>
      <value value="6162518"/>
      <value value="2860263"/>
      <value value="3535726"/>
      <value value="6940795"/>
      <value value="2309773"/>
      <value value="715005"/>
      <value value="8952285"/>
      <value value="5807792"/>
      <value value="8172651"/>
      <value value="6125963"/>
      <value value="5296833"/>
      <value value="2357732"/>
      <value value="6818083"/>
      <value value="3826973"/>
      <value value="3107720"/>
      <value value="787990"/>
      <value value="4533268"/>
      <value value="542976"/>
      <value value="8107658"/>
      <value value="2503748"/>
      <value value="3914133"/>
      <value value="6148845"/>
      <value value="883795"/>
      <value value="8166559"/>
      <value value="5602568"/>
      <value value="1317389"/>
      <value value="48318"/>
      <value value="4246759"/>
      <value value="2635009"/>
      <value value="4772354"/>
      <value value="4272825"/>
      <value value="1997632"/>
      <value value="9446574"/>
      <value value="1075615"/>
      <value value="5520478"/>
      <value value="9882101"/>
      <value value="6668055"/>
      <value value="8945066"/>
      <value value="3666979"/>
      <value value="5699081"/>
      <value value="6428483"/>
      <value value="1560431"/>
      <value value="5875788"/>
      <value value="6536208"/>
      <value value="5695868"/>
      <value value="1207229"/>
      <value value="11415"/>
      <value value="3959657"/>
      <value value="3793572"/>
      <value value="258920"/>
      <value value="1619299"/>
      <value value="826149"/>
      <value value="2481643"/>
      <value value="4106446"/>
      <value value="3438701"/>
      <value value="3958267"/>
      <value value="5703359"/>
      <value value="95660"/>
      <value value="3872924"/>
      <value value="1281387"/>
      <value value="1381596"/>
      <value value="7927640"/>
      <value value="3534064"/>
      <value value="4097585"/>
      <value value="3673751"/>
      <value value="1395821"/>
      <value value="1611276"/>
      <value value="1237638"/>
      <value value="1499350"/>
      <value value="126671"/>
      <value value="4821356"/>
      <value value="4019857"/>
      <value value="4416456"/>
      <value value="1568099"/>
      <value value="3917534"/>
      <value value="989578"/>
      <value value="9333656"/>
      <value value="476842"/>
      <value value="3136747"/>
      <value value="228998"/>
      <value value="3733469"/>
      <value value="1688276"/>
      <value value="8453862"/>
      <value value="3052057"/>
      <value value="1318246"/>
      <value value="172418"/>
      <value value="8690162"/>
      <value value="5087838"/>
      <value value="1930573"/>
      <value value="527652"/>
      <value value="2606232"/>
      <value value="4651871"/>
      <value value="7396100"/>
      <value value="4685150"/>
      <value value="8318912"/>
      <value value="5179521"/>
      <value value="2970571"/>
      <value value="6862005"/>
      <value value="8199596"/>
      <value value="2938905"/>
      <value value="3281024"/>
      <value value="8040268"/>
      <value value="1233138"/>
      <value value="2243149"/>
      <value value="2477072"/>
      <value value="936296"/>
      <value value="7547229"/>
      <value value="3568417"/>
      <value value="9574172"/>
      <value value="2544266"/>
      <value value="3751674"/>
      <value value="397464"/>
      <value value="2101185"/>
      <value value="3913245"/>
      <value value="2330252"/>
      <value value="9102031"/>
      <value value="8052433"/>
      <value value="5541191"/>
      <value value="9577047"/>
      <value value="8199497"/>
      <value value="4645503"/>
      <value value="3427608"/>
      <value value="7620463"/>
      <value value="4804917"/>
      <value value="7158049"/>
      <value value="7679496"/>
      <value value="5834047"/>
      <value value="9528948"/>
      <value value="3022150"/>
      <value value="5638242"/>
      <value value="7248909"/>
      <value value="2403187"/>
      <value value="7767676"/>
      <value value="879365"/>
      <value value="4854691"/>
      <value value="1397267"/>
      <value value="53542"/>
      <value value="7915363"/>
      <value value="1086358"/>
      <value value="3680439"/>
      <value value="4404274"/>
      <value value="4332820"/>
      <value value="4579512"/>
      <value value="5231709"/>
      <value value="3183315"/>
      <value value="437800"/>
      <value value="2346676"/>
      <value value="6453289"/>
      <value value="112276"/>
      <value value="126373"/>
      <value value="9204255"/>
      <value value="9419876"/>
      <value value="7845704"/>
      <value value="6911325"/>
      <value value="6735588"/>
      <value value="7714831"/>
      <value value="1930675"/>
      <value value="3328294"/>
      <value value="2082060"/>
      <value value="7628480"/>
      <value value="879724"/>
      <value value="9208144"/>
      <value value="190158"/>
      <value value="9117154"/>
      <value value="8297572"/>
      <value value="1766504"/>
      <value value="9775791"/>
      <value value="7829496"/>
      <value value="1657456"/>
      <value value="4610755"/>
      <value value="3364753"/>
      <value value="3589412"/>
      <value value="9646488"/>
      <value value="3258385"/>
      <value value="1839694"/>
      <value value="6559753"/>
      <value value="9847734"/>
      <value value="6060727"/>
      <value value="1482069"/>
      <value value="9713030"/>
      <value value="1977784"/>
      <value value="5800700"/>
      <value value="8200773"/>
      <value value="839448"/>
      <value value="6319759"/>
      <value value="3615295"/>
      <value value="4040063"/>
      <value value="7873338"/>
      <value value="9024093"/>
      <value value="8604634"/>
      <value value="4668976"/>
      <value value="5155648"/>
      <value value="3792020"/>
      <value value="5194249"/>
      <value value="2669506"/>
      <value value="897610"/>
      <value value="7986289"/>
      <value value="4482519"/>
      <value value="8044455"/>
      <value value="595538"/>
      <value value="5040490"/>
      <value value="3118977"/>
      <value value="2785502"/>
      <value value="2309505"/>
      <value value="4943153"/>
      <value value="2574889"/>
      <value value="2468570"/>
      <value value="8842282"/>
      <value value="3358295"/>
      <value value="9536079"/>
      <value value="1904462"/>
      <value value="1996915"/>
      <value value="9447707"/>
      <value value="8548689"/>
      <value value="788452"/>
      <value value="7399820"/>
      <value value="8505538"/>
      <value value="5405534"/>
      <value value="4291250"/>
      <value value="8276000"/>
      <value value="6701628"/>
      <value value="1916566"/>
      <value value="2291860"/>
      <value value="3828635"/>
      <value value="6431509"/>
      <value value="3902169"/>
      <value value="1787310"/>
      <value value="920767"/>
      <value value="9265480"/>
      <value value="4144343"/>
      <value value="8678714"/>
      <value value="9939846"/>
      <value value="9746019"/>
      <value value="8946996"/>
      <value value="7527768"/>
      <value value="6159296"/>
      <value value="252968"/>
      <value value="8859820"/>
      <value value="9346511"/>
      <value value="864547"/>
      <value value="8737987"/>
      <value value="2802370"/>
      <value value="9905472"/>
      <value value="1279343"/>
      <value value="2659464"/>
      <value value="4891528"/>
      <value value="7160968"/>
      <value value="8070117"/>
      <value value="1952855"/>
      <value value="2083709"/>
      <value value="3888268"/>
      <value value="6928610"/>
      <value value="2582653"/>
      <value value="4305527"/>
      <value value="4499319"/>
      <value value="9128636"/>
      <value value="3029840"/>
      <value value="2036719"/>
      <value value="4739781"/>
      <value value="2503449"/>
      <value value="1762025"/>
      <value value="2790591"/>
      <value value="3518316"/>
      <value value="9226141"/>
      <value value="7892820"/>
      <value value="2868422"/>
      <value value="2576198"/>
      <value value="8177203"/>
      <value value="859205"/>
      <value value="9281721"/>
      <value value="7910615"/>
      <value value="706827"/>
      <value value="5661663"/>
      <value value="2037172"/>
      <value value="6848633"/>
      <value value="8046971"/>
      <value value="770736"/>
      <value value="5781654"/>
      <value value="3551179"/>
      <value value="7925362"/>
      <value value="5324029"/>
      <value value="5147081"/>
      <value value="3532156"/>
      <value value="7502499"/>
      <value value="4354541"/>
      <value value="2199849"/>
      <value value="2523704"/>
      <value value="897353"/>
      <value value="7282112"/>
      <value value="2634631"/>
      <value value="9542303"/>
      <value value="124112"/>
      <value value="9207954"/>
      <value value="435813"/>
      <value value="8675056"/>
      <value value="768037"/>
      <value value="3078670"/>
      <value value="3682279"/>
      <value value="9493883"/>
      <value value="3500125"/>
      <value value="186207"/>
      <value value="461825"/>
      <value value="7247280"/>
      <value value="7856620"/>
      <value value="7125522"/>
      <value value="8455539"/>
      <value value="6472662"/>
      <value value="9595050"/>
      <value value="8790328"/>
      <value value="5111752"/>
      <value value="877765"/>
      <value value="3580877"/>
      <value value="3995669"/>
      <value value="8025562"/>
      <value value="2506911"/>
      <value value="8996496"/>
      <value value="1567828"/>
      <value value="7191017"/>
      <value value="5527958"/>
      <value value="3063963"/>
      <value value="1340688"/>
      <value value="7371046"/>
      <value value="4827404"/>
      <value value="2671684"/>
      <value value="5056766"/>
      <value value="8763821"/>
      <value value="4879039"/>
      <value value="1035094"/>
      <value value="1010047"/>
      <value value="2662019"/>
      <value value="4124053"/>
      <value value="7620425"/>
      <value value="6274351"/>
      <value value="2831251"/>
      <value value="7906792"/>
      <value value="2185591"/>
      <value value="5117484"/>
      <value value="5622779"/>
      <value value="5933757"/>
      <value value="3228050"/>
      <value value="7437800"/>
      <value value="5326640"/>
      <value value="8983741"/>
      <value value="9869711"/>
      <value value="5310315"/>
      <value value="4425269"/>
      <value value="883922"/>
      <value value="697922"/>
      <value value="8526223"/>
      <value value="3029022"/>
      <value value="1323932"/>
      <value value="4077073"/>
      <value value="1969880"/>
      <value value="8084642"/>
      <value value="350829"/>
      <value value="838433"/>
      <value value="2699709"/>
      <value value="380268"/>
      <value value="8700885"/>
      <value value="7745629"/>
      <value value="497482"/>
      <value value="7136648"/>
      <value value="1905071"/>
      <value value="6796417"/>
      <value value="7392836"/>
      <value value="7401986"/>
      <value value="9672131"/>
      <value value="5594274"/>
      <value value="2811614"/>
      <value value="7538279"/>
      <value value="1047312"/>
      <value value="135711"/>
      <value value="4272721"/>
      <value value="325684"/>
      <value value="9624625"/>
      <value value="9431295"/>
      <value value="3112689"/>
      <value value="6057316"/>
      <value value="3398875"/>
      <value value="1762616"/>
      <value value="1311462"/>
      <value value="9453623"/>
      <value value="2397004"/>
      <value value="6354233"/>
      <value value="9061373"/>
      <value value="293392"/>
      <value value="8626037"/>
      <value value="674046"/>
      <value value="2115978"/>
      <value value="8448947"/>
      <value value="8236534"/>
      <value value="7243907"/>
      <value value="487218"/>
      <value value="4188590"/>
      <value value="9303454"/>
      <value value="8590131"/>
      <value value="5378191"/>
      <value value="1061387"/>
      <value value="2846853"/>
      <value value="3797482"/>
      <value value="866286"/>
      <value value="4362495"/>
      <value value="1564310"/>
      <value value="4703377"/>
      <value value="6823409"/>
      <value value="7348713"/>
      <value value="3701329"/>
      <value value="7853973"/>
      <value value="2391638"/>
      <value value="1903785"/>
      <value value="9921192"/>
      <value value="8312087"/>
      <value value="8096201"/>
      <value value="4956260"/>
      <value value="8556024"/>
      <value value="3464038"/>
      <value value="7203948"/>
      <value value="4886913"/>
      <value value="474411"/>
      <value value="5244518"/>
      <value value="1716786"/>
      <value value="2441606"/>
      <value value="3420556"/>
      <value value="2920065"/>
      <value value="4464695"/>
      <value value="8168483"/>
      <value value="1445234"/>
      <value value="9281101"/>
      <value value="5747846"/>
      <value value="7746422"/>
      <value value="3588272"/>
      <value value="3728119"/>
      <value value="2155738"/>
      <value value="5219210"/>
      <value value="7800401"/>
      <value value="777420"/>
      <value value="1393495"/>
      <value value="1134538"/>
      <value value="3527666"/>
      <value value="1338014"/>
      <value value="6736216"/>
      <value value="9233048"/>
      <value value="6910209"/>
      <value value="6365613"/>
      <value value="7256434"/>
      <value value="724087"/>
      <value value="4959160"/>
      <value value="2101413"/>
      <value value="4510128"/>
      <value value="293866"/>
      <value value="22653"/>
      <value value="3007598"/>
      <value value="2926386"/>
      <value value="5870803"/>
      <value value="5508469"/>
      <value value="1436899"/>
      <value value="3770932"/>
      <value value="1114118"/>
      <value value="3205424"/>
      <value value="6498553"/>
      <value value="7735822"/>
      <value value="5270258"/>
      <value value="8663749"/>
      <value value="7373754"/>
      <value value="1967409"/>
      <value value="9581173"/>
      <value value="3086640"/>
      <value value="6883068"/>
      <value value="6746804"/>
      <value value="823060"/>
      <value value="6047091"/>
      <value value="6568401"/>
      <value value="8072167"/>
      <value value="5247921"/>
      <value value="8397255"/>
      <value value="6689774"/>
      <value value="8127471"/>
      <value value="8912887"/>
      <value value="2199485"/>
      <value value="205235"/>
      <value value="9753689"/>
      <value value="3957468"/>
      <value value="394875"/>
      <value value="4152435"/>
      <value value="7914537"/>
      <value value="6219832"/>
      <value value="9233849"/>
      <value value="8219744"/>
      <value value="6212559"/>
      <value value="9663273"/>
      <value value="1148056"/>
      <value value="22244"/>
      <value value="3772271"/>
      <value value="3529324"/>
      <value value="8435940"/>
      <value value="5834572"/>
      <value value="8543035"/>
      <value value="7644751"/>
      <value value="5560521"/>
      <value value="4447325"/>
      <value value="3524283"/>
      <value value="6830108"/>
      <value value="4073128"/>
      <value value="1896137"/>
      <value value="5403483"/>
      <value value="1979301"/>
      <value value="4993615"/>
      <value value="449668"/>
      <value value="8388430"/>
      <value value="7074549"/>
      <value value="3496408"/>
      <value value="3829697"/>
      <value value="8557340"/>
      <value value="6631526"/>
      <value value="7299030"/>
      <value value="8916847"/>
      <value value="1806818"/>
      <value value="807775"/>
      <value value="4778417"/>
      <value value="8330548"/>
      <value value="7449399"/>
      <value value="8416682"/>
      <value value="9133911"/>
      <value value="2274722"/>
      <value value="3815123"/>
      <value value="4115504"/>
      <value value="8753012"/>
      <value value="1249284"/>
      <value value="808060"/>
      <value value="6536175"/>
      <value value="8941651"/>
      <value value="9837424"/>
      <value value="2465869"/>
      <value value="64783"/>
      <value value="2126472"/>
      <value value="1558238"/>
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
  <experiment name="R test 7" repetitions="1" runMetricsEveryStep="false">
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
      <value value="7981708"/>
      <value value="6777190"/>
      <value value="2559464"/>
      <value value="4493117"/>
      <value value="7045795"/>
      <value value="942052"/>
      <value value="7880338"/>
      <value value="366692"/>
      <value value="3664493"/>
      <value value="7511184"/>
      <value value="9990583"/>
      <value value="9798238"/>
      <value value="4232330"/>
      <value value="2158630"/>
      <value value="6501974"/>
      <value value="9927597"/>
      <value value="493025"/>
      <value value="6330647"/>
      <value value="5895329"/>
      <value value="7237432"/>
      <value value="3891784"/>
      <value value="8063092"/>
      <value value="7529562"/>
      <value value="8967630"/>
      <value value="4187947"/>
      <value value="9364132"/>
      <value value="6532144"/>
      <value value="637991"/>
      <value value="4584285"/>
      <value value="9403606"/>
      <value value="8615892"/>
      <value value="2047806"/>
      <value value="7839936"/>
      <value value="6413555"/>
      <value value="2437017"/>
      <value value="2000049"/>
      <value value="5762945"/>
      <value value="469052"/>
      <value value="951539"/>
      <value value="6189054"/>
      <value value="2834439"/>
      <value value="8531801"/>
      <value value="7930086"/>
      <value value="9959424"/>
      <value value="944150"/>
      <value value="7376424"/>
      <value value="6649197"/>
      <value value="9988227"/>
      <value value="1470370"/>
      <value value="3327311"/>
      <value value="4553176"/>
      <value value="6476695"/>
      <value value="4156830"/>
      <value value="5128420"/>
      <value value="1217764"/>
      <value value="8871193"/>
      <value value="3727581"/>
      <value value="1884707"/>
      <value value="9240179"/>
      <value value="1075279"/>
      <value value="248961"/>
      <value value="1368039"/>
      <value value="7301078"/>
      <value value="3648030"/>
      <value value="4596786"/>
      <value value="4341541"/>
      <value value="4367195"/>
      <value value="6591815"/>
      <value value="1225314"/>
      <value value="4518968"/>
      <value value="1647004"/>
      <value value="3438629"/>
      <value value="405810"/>
      <value value="5341547"/>
      <value value="2210535"/>
      <value value="2493828"/>
      <value value="1221225"/>
      <value value="3582619"/>
      <value value="636118"/>
      <value value="8946650"/>
      <value value="4073453"/>
      <value value="1173304"/>
      <value value="1913462"/>
      <value value="4699337"/>
      <value value="797538"/>
      <value value="1620405"/>
      <value value="2866630"/>
      <value value="8489441"/>
      <value value="3559467"/>
      <value value="6331852"/>
      <value value="9853163"/>
      <value value="4565275"/>
      <value value="2417163"/>
      <value value="890964"/>
      <value value="3739042"/>
      <value value="9968693"/>
      <value value="8824475"/>
      <value value="827092"/>
      <value value="7068569"/>
      <value value="8078066"/>
      <value value="5492690"/>
      <value value="5827365"/>
      <value value="4365595"/>
      <value value="2486289"/>
      <value value="5087339"/>
      <value value="6564450"/>
      <value value="8380928"/>
      <value value="7622143"/>
      <value value="8847502"/>
      <value value="9907143"/>
      <value value="7041521"/>
      <value value="351292"/>
      <value value="7977041"/>
      <value value="2305353"/>
      <value value="860209"/>
      <value value="3364241"/>
      <value value="6412833"/>
      <value value="6005303"/>
      <value value="270532"/>
      <value value="8087672"/>
      <value value="4133762"/>
      <value value="1132347"/>
      <value value="3976543"/>
      <value value="1428871"/>
      <value value="6203502"/>
      <value value="592641"/>
      <value value="1737213"/>
      <value value="9108721"/>
      <value value="268975"/>
      <value value="3709381"/>
      <value value="7754073"/>
      <value value="8290268"/>
      <value value="1001303"/>
      <value value="745806"/>
      <value value="9125236"/>
      <value value="6289334"/>
      <value value="3499447"/>
      <value value="5577374"/>
      <value value="6859668"/>
      <value value="5861188"/>
      <value value="4027277"/>
      <value value="2601162"/>
      <value value="8298652"/>
      <value value="380789"/>
      <value value="1045088"/>
      <value value="6312401"/>
      <value value="3482473"/>
      <value value="1047563"/>
      <value value="2299641"/>
      <value value="7740941"/>
      <value value="842858"/>
      <value value="8728964"/>
      <value value="2068904"/>
      <value value="960714"/>
      <value value="5562518"/>
      <value value="209878"/>
      <value value="3142510"/>
      <value value="4534786"/>
      <value value="1208701"/>
      <value value="118977"/>
      <value value="3113361"/>
      <value value="4378664"/>
      <value value="5946547"/>
      <value value="2630595"/>
      <value value="6470917"/>
      <value value="9828540"/>
      <value value="6622256"/>
      <value value="1577998"/>
      <value value="4808998"/>
      <value value="9462572"/>
      <value value="361743"/>
      <value value="6033812"/>
      <value value="5213602"/>
      <value value="2049395"/>
      <value value="550645"/>
      <value value="2937783"/>
      <value value="4381726"/>
      <value value="4199804"/>
      <value value="2894962"/>
      <value value="2743645"/>
      <value value="2650935"/>
      <value value="3508445"/>
      <value value="3831693"/>
      <value value="167832"/>
      <value value="2070104"/>
      <value value="3265222"/>
      <value value="105823"/>
      <value value="8742795"/>
      <value value="7830995"/>
      <value value="5148525"/>
      <value value="1985704"/>
      <value value="4855906"/>
      <value value="7737148"/>
      <value value="3196847"/>
      <value value="9269000"/>
      <value value="2347423"/>
      <value value="6965052"/>
      <value value="3770615"/>
      <value value="8308236"/>
      <value value="5264847"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;StageCal None&quot;"/>
      <value value="&quot;StageCal Isolate&quot;"/>
      <value value="&quot;StageCal_1&quot;"/>
      <value value="&quot;StageCal_1b&quot;"/>
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
      <value value="76"/>
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
      <value value="0.36"/>
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
      <value value="40"/>
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
      <value value="20"/>
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
      <value value="2500000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
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
      <value value="8.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Big R Test Duplicate" repetitions="1" runMetricsEveryStep="false">
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
      <value value="7718895"/>
      <value value="3112539"/>
      <value value="411040"/>
      <value value="7911440"/>
      <value value="3708070"/>
      <value value="3613568"/>
      <value value="4735114"/>
      <value value="4125068"/>
      <value value="2073961"/>
      <value value="8345203"/>
      <value value="7659774"/>
      <value value="8532508"/>
      <value value="7597641"/>
      <value value="3292367"/>
      <value value="8823363"/>
      <value value="7007207"/>
      <value value="2243958"/>
      <value value="8469033"/>
      <value value="382536"/>
      <value value="584797"/>
      <value value="6497435"/>
      <value value="10435"/>
      <value value="962209"/>
      <value value="3358343"/>
      <value value="6778353"/>
      <value value="2192245"/>
      <value value="6650992"/>
      <value value="7216142"/>
      <value value="7969284"/>
      <value value="5930886"/>
      <value value="4875286"/>
      <value value="1477132"/>
      <value value="8263800"/>
      <value value="7542875"/>
      <value value="3212083"/>
      <value value="3214868"/>
      <value value="915786"/>
      <value value="4371556"/>
      <value value="6712216"/>
      <value value="8056765"/>
      <value value="9089918"/>
      <value value="6892276"/>
      <value value="2429792"/>
      <value value="946450"/>
      <value value="6896983"/>
      <value value="7613132"/>
      <value value="9641468"/>
      <value value="8880403"/>
      <value value="5950572"/>
      <value value="1441785"/>
      <value value="8716116"/>
      <value value="6654692"/>
      <value value="9388202"/>
      <value value="9855400"/>
      <value value="5127863"/>
      <value value="4302572"/>
      <value value="477617"/>
      <value value="2336423"/>
      <value value="6304228"/>
      <value value="8516486"/>
      <value value="4338740"/>
      <value value="4731645"/>
      <value value="8861816"/>
      <value value="8681955"/>
      <value value="5538102"/>
      <value value="5407364"/>
      <value value="2986003"/>
      <value value="3750305"/>
      <value value="6915813"/>
      <value value="1690304"/>
      <value value="8463886"/>
      <value value="9341047"/>
      <value value="5977227"/>
      <value value="5595142"/>
      <value value="6327214"/>
      <value value="5813880"/>
      <value value="5986721"/>
      <value value="9375879"/>
      <value value="6687031"/>
      <value value="2842618"/>
      <value value="3585525"/>
      <value value="7672003"/>
      <value value="7990283"/>
      <value value="174090"/>
      <value value="2244464"/>
      <value value="1475007"/>
      <value value="5027585"/>
      <value value="3895170"/>
      <value value="4559631"/>
      <value value="9934717"/>
      <value value="5318488"/>
      <value value="6303638"/>
      <value value="9827540"/>
      <value value="3980107"/>
      <value value="3525963"/>
      <value value="383687"/>
      <value value="652213"/>
      <value value="9429860"/>
      <value value="4312940"/>
      <value value="4258827"/>
      <value value="3544804"/>
      <value value="8146670"/>
      <value value="4645139"/>
      <value value="5513703"/>
      <value value="1172114"/>
      <value value="7869790"/>
      <value value="5471278"/>
      <value value="5323059"/>
      <value value="5206443"/>
      <value value="970686"/>
      <value value="6996958"/>
      <value value="2385006"/>
      <value value="89661"/>
      <value value="9316935"/>
      <value value="3715674"/>
      <value value="6069555"/>
      <value value="4818989"/>
      <value value="8862648"/>
      <value value="5062216"/>
      <value value="6787825"/>
      <value value="8864700"/>
      <value value="4448603"/>
      <value value="9594504"/>
      <value value="8050937"/>
      <value value="2561158"/>
      <value value="5833736"/>
      <value value="4210927"/>
      <value value="568003"/>
      <value value="8260848"/>
      <value value="8755787"/>
      <value value="7926623"/>
      <value value="4608681"/>
      <value value="9088959"/>
      <value value="7087616"/>
      <value value="8786912"/>
      <value value="6618381"/>
      <value value="5059497"/>
      <value value="9943820"/>
      <value value="2606855"/>
      <value value="9457217"/>
      <value value="8002040"/>
      <value value="8990469"/>
      <value value="3989385"/>
      <value value="5418508"/>
      <value value="5620060"/>
      <value value="9193551"/>
      <value value="1317120"/>
      <value value="5097064"/>
      <value value="3686216"/>
      <value value="1033520"/>
      <value value="6525578"/>
      <value value="6207983"/>
      <value value="5096353"/>
      <value value="5662456"/>
      <value value="6162131"/>
      <value value="9855693"/>
      <value value="6341593"/>
      <value value="4269269"/>
      <value value="1248520"/>
      <value value="9478426"/>
      <value value="3336952"/>
      <value value="9242986"/>
      <value value="4533431"/>
      <value value="3186957"/>
      <value value="6864239"/>
      <value value="8659564"/>
      <value value="9651831"/>
      <value value="2611925"/>
      <value value="5667549"/>
      <value value="3778800"/>
      <value value="7459892"/>
      <value value="2926572"/>
      <value value="1663125"/>
      <value value="4054141"/>
      <value value="9752135"/>
      <value value="425194"/>
      <value value="3843713"/>
      <value value="2776391"/>
      <value value="4609036"/>
      <value value="6147680"/>
      <value value="2292558"/>
      <value value="8156934"/>
      <value value="1388532"/>
      <value value="7333861"/>
      <value value="4299493"/>
      <value value="4406344"/>
      <value value="1252160"/>
      <value value="2736105"/>
      <value value="7576665"/>
      <value value="3702498"/>
      <value value="5928506"/>
      <value value="8644357"/>
      <value value="9996117"/>
      <value value="6770897"/>
      <value value="7853724"/>
      <value value="5217561"/>
      <value value="2058236"/>
      <value value="4351514"/>
      <value value="1646637"/>
      <value value="4095530"/>
      <value value="4006351"/>
      <value value="8683574"/>
      <value value="5003621"/>
      <value value="7836165"/>
      <value value="663394"/>
      <value value="2429868"/>
      <value value="7215841"/>
      <value value="5770794"/>
      <value value="5886251"/>
      <value value="5280580"/>
      <value value="2275830"/>
      <value value="8258399"/>
      <value value="9957552"/>
      <value value="3803381"/>
      <value value="1496563"/>
      <value value="2211342"/>
      <value value="6197327"/>
      <value value="8114890"/>
      <value value="9624900"/>
      <value value="7336065"/>
      <value value="7130382"/>
      <value value="4141777"/>
      <value value="8553573"/>
      <value value="4502231"/>
      <value value="3602857"/>
      <value value="809646"/>
      <value value="1176587"/>
      <value value="8933653"/>
      <value value="9326259"/>
      <value value="7858929"/>
      <value value="1065112"/>
      <value value="9896952"/>
      <value value="6122655"/>
      <value value="6602489"/>
      <value value="1609099"/>
      <value value="7118412"/>
      <value value="5459373"/>
      <value value="7075366"/>
      <value value="4657372"/>
      <value value="5228206"/>
      <value value="8614928"/>
      <value value="542375"/>
      <value value="4896620"/>
      <value value="5315509"/>
      <value value="6220268"/>
      <value value="6698069"/>
      <value value="1072271"/>
      <value value="1203810"/>
      <value value="416838"/>
      <value value="8714670"/>
      <value value="9795767"/>
      <value value="3896500"/>
      <value value="4851108"/>
      <value value="5650205"/>
      <value value="5214336"/>
      <value value="4201607"/>
      <value value="9068150"/>
      <value value="2066692"/>
      <value value="9374258"/>
      <value value="2004832"/>
      <value value="3468483"/>
      <value value="2656338"/>
      <value value="858824"/>
      <value value="8534672"/>
      <value value="7591518"/>
      <value value="5333737"/>
      <value value="3052065"/>
      <value value="4539439"/>
      <value value="9833406"/>
      <value value="1740349"/>
      <value value="221098"/>
      <value value="7966232"/>
      <value value="9798589"/>
      <value value="350550"/>
      <value value="491829"/>
      <value value="6948048"/>
      <value value="4848140"/>
      <value value="8174815"/>
      <value value="3517045"/>
      <value value="7314699"/>
      <value value="8376470"/>
      <value value="3912926"/>
      <value value="8759426"/>
      <value value="7499340"/>
      <value value="880163"/>
      <value value="1993715"/>
      <value value="5009910"/>
      <value value="6754018"/>
      <value value="7378822"/>
      <value value="6858698"/>
      <value value="8615733"/>
      <value value="8676950"/>
      <value value="3625479"/>
      <value value="6094778"/>
      <value value="1101176"/>
      <value value="2560571"/>
      <value value="4536605"/>
      <value value="2035230"/>
      <value value="7464062"/>
      <value value="1131168"/>
      <value value="640309"/>
      <value value="8640917"/>
      <value value="3577173"/>
      <value value="6314727"/>
      <value value="9264064"/>
      <value value="3060887"/>
      <value value="3333816"/>
      <value value="5105921"/>
      <value value="2991088"/>
      <value value="4853970"/>
      <value value="4241127"/>
      <value value="5384044"/>
      <value value="9025786"/>
      <value value="4362436"/>
      <value value="4315457"/>
      <value value="2788614"/>
      <value value="7217633"/>
      <value value="1013893"/>
      <value value="5618857"/>
      <value value="3253852"/>
      <value value="7062211"/>
      <value value="3716634"/>
      <value value="4763047"/>
      <value value="8045973"/>
      <value value="1670362"/>
      <value value="2352779"/>
      <value value="9252128"/>
      <value value="6713408"/>
      <value value="6779086"/>
      <value value="4194390"/>
      <value value="3696111"/>
      <value value="9740577"/>
      <value value="5862257"/>
      <value value="4222500"/>
      <value value="5489343"/>
      <value value="109093"/>
      <value value="3674936"/>
      <value value="8550485"/>
      <value value="1167667"/>
      <value value="5576411"/>
      <value value="6890195"/>
      <value value="6313041"/>
      <value value="8022848"/>
      <value value="7578813"/>
      <value value="5243461"/>
      <value value="5534350"/>
      <value value="3210127"/>
      <value value="1897260"/>
      <value value="2199634"/>
      <value value="1435209"/>
      <value value="5942225"/>
      <value value="3360765"/>
      <value value="4220830"/>
      <value value="8970736"/>
      <value value="3057519"/>
      <value value="7634331"/>
      <value value="7690545"/>
      <value value="4824365"/>
      <value value="3084905"/>
      <value value="2363801"/>
      <value value="6997516"/>
      <value value="1407182"/>
      <value value="1704258"/>
      <value value="8378020"/>
      <value value="3469797"/>
      <value value="5435050"/>
      <value value="5071849"/>
      <value value="2942268"/>
      <value value="6907258"/>
      <value value="9511083"/>
      <value value="9511336"/>
      <value value="2946942"/>
      <value value="6505874"/>
      <value value="7502407"/>
      <value value="9324702"/>
      <value value="3595489"/>
      <value value="5978444"/>
      <value value="1705183"/>
      <value value="4089825"/>
      <value value="1485596"/>
      <value value="9792958"/>
      <value value="3567745"/>
      <value value="1300129"/>
      <value value="8298155"/>
      <value value="8712458"/>
      <value value="792944"/>
      <value value="1081933"/>
      <value value="67705"/>
      <value value="7252477"/>
      <value value="9440854"/>
      <value value="8289789"/>
      <value value="4093277"/>
      <value value="707808"/>
      <value value="8810415"/>
      <value value="7956636"/>
      <value value="4044689"/>
      <value value="7561389"/>
      <value value="7869199"/>
      <value value="125712"/>
      <value value="8886516"/>
      <value value="9444961"/>
      <value value="1616586"/>
      <value value="1419282"/>
      <value value="1827031"/>
      <value value="3539152"/>
      <value value="2319226"/>
      <value value="4789420"/>
      <value value="3843355"/>
      <value value="4257091"/>
      <value value="6113880"/>
      <value value="4745077"/>
      <value value="9768063"/>
      <value value="3691579"/>
      <value value="4359387"/>
      <value value="2497331"/>
      <value value="5821207"/>
      <value value="8537310"/>
      <value value="1076526"/>
      <value value="542199"/>
      <value value="5726017"/>
      <value value="1501543"/>
      <value value="4850323"/>
      <value value="3728454"/>
      <value value="6025589"/>
      <value value="4948762"/>
      <value value="4696926"/>
      <value value="1211954"/>
      <value value="2522501"/>
      <value value="6795657"/>
      <value value="7727078"/>
      <value value="6568277"/>
      <value value="7462701"/>
      <value value="4921437"/>
      <value value="2323492"/>
      <value value="5610271"/>
      <value value="34178"/>
      <value value="4244663"/>
      <value value="422621"/>
      <value value="1735720"/>
      <value value="3317899"/>
      <value value="5254414"/>
      <value value="3997231"/>
      <value value="7161865"/>
      <value value="9951599"/>
      <value value="4646764"/>
      <value value="6151281"/>
      <value value="4949183"/>
      <value value="1919060"/>
      <value value="6063516"/>
      <value value="9150896"/>
      <value value="2697838"/>
      <value value="5345125"/>
      <value value="9388111"/>
      <value value="8552983"/>
      <value value="8874509"/>
      <value value="1987059"/>
      <value value="9535554"/>
      <value value="8113291"/>
      <value value="3136616"/>
      <value value="3810622"/>
      <value value="2259676"/>
      <value value="2478345"/>
      <value value="7605460"/>
      <value value="4242077"/>
      <value value="9943807"/>
      <value value="5932535"/>
      <value value="9009285"/>
      <value value="7058747"/>
      <value value="5234658"/>
      <value value="1218311"/>
      <value value="7415917"/>
      <value value="3022133"/>
      <value value="1062575"/>
      <value value="9888410"/>
      <value value="2270131"/>
      <value value="8850097"/>
      <value value="4171919"/>
      <value value="756968"/>
      <value value="2305998"/>
      <value value="2166187"/>
      <value value="1056588"/>
      <value value="6051798"/>
      <value value="9090307"/>
      <value value="4948796"/>
      <value value="5833178"/>
      <value value="4857629"/>
      <value value="6369304"/>
      <value value="6849548"/>
      <value value="6102075"/>
      <value value="3406009"/>
      <value value="7248543"/>
      <value value="1030188"/>
      <value value="6756052"/>
      <value value="5373150"/>
      <value value="696827"/>
      <value value="4435736"/>
      <value value="9072009"/>
      <value value="9161840"/>
      <value value="3255284"/>
      <value value="2324777"/>
      <value value="7602308"/>
      <value value="7387875"/>
      <value value="6103004"/>
      <value value="7390579"/>
      <value value="1036651"/>
      <value value="1084489"/>
      <value value="4340894"/>
      <value value="1749289"/>
      <value value="568020"/>
      <value value="9816238"/>
      <value value="5508438"/>
      <value value="6158255"/>
      <value value="8444954"/>
      <value value="2824281"/>
      <value value="955304"/>
      <value value="7041501"/>
      <value value="251082"/>
      <value value="1254883"/>
      <value value="1681590"/>
      <value value="8240758"/>
      <value value="2128837"/>
      <value value="3428101"/>
      <value value="3534609"/>
      <value value="8129916"/>
      <value value="2433096"/>
      <value value="9601099"/>
      <value value="7099627"/>
      <value value="6701507"/>
      <value value="6495828"/>
      <value value="7196347"/>
      <value value="3487414"/>
      <value value="7010697"/>
      <value value="6634718"/>
      <value value="9857677"/>
      <value value="2395440"/>
      <value value="4614120"/>
      <value value="3521902"/>
      <value value="1504826"/>
      <value value="7708349"/>
      <value value="1531172"/>
      <value value="9442536"/>
      <value value="6328653"/>
      <value value="4356006"/>
      <value value="784268"/>
      <value value="3071663"/>
      <value value="7739203"/>
      <value value="793246"/>
      <value value="8226131"/>
      <value value="7872438"/>
      <value value="6895725"/>
      <value value="5878033"/>
      <value value="1843237"/>
      <value value="5587230"/>
      <value value="7527127"/>
      <value value="1721774"/>
      <value value="6781478"/>
      <value value="2220419"/>
      <value value="1316550"/>
      <value value="6348168"/>
      <value value="1424366"/>
      <value value="5532793"/>
      <value value="2156623"/>
      <value value="321103"/>
      <value value="4046481"/>
      <value value="4758439"/>
      <value value="7759050"/>
      <value value="4568033"/>
      <value value="8194321"/>
      <value value="452171"/>
      <value value="5179956"/>
      <value value="3676386"/>
      <value value="5298218"/>
      <value value="1466762"/>
      <value value="3692575"/>
      <value value="542036"/>
      <value value="4798611"/>
      <value value="8429047"/>
      <value value="7850650"/>
      <value value="9644853"/>
      <value value="3389691"/>
      <value value="2764448"/>
      <value value="7761537"/>
      <value value="1209788"/>
      <value value="3398803"/>
      <value value="2750582"/>
      <value value="3467460"/>
      <value value="8196077"/>
      <value value="1942761"/>
      <value value="7952391"/>
      <value value="2746920"/>
      <value value="1893380"/>
      <value value="8904502"/>
      <value value="2825759"/>
      <value value="1865911"/>
      <value value="5219353"/>
      <value value="575709"/>
      <value value="3760686"/>
      <value value="5959355"/>
      <value value="4033915"/>
      <value value="4165261"/>
      <value value="6816498"/>
      <value value="3747405"/>
      <value value="5533667"/>
      <value value="371720"/>
      <value value="3138482"/>
      <value value="6500661"/>
      <value value="3479987"/>
      <value value="1033298"/>
      <value value="3609110"/>
      <value value="8790688"/>
      <value value="3838643"/>
      <value value="1654141"/>
      <value value="7881878"/>
      <value value="59587"/>
      <value value="4869356"/>
      <value value="2581557"/>
      <value value="2185351"/>
      <value value="5639448"/>
      <value value="3952778"/>
      <value value="5087461"/>
      <value value="1744549"/>
      <value value="1924833"/>
      <value value="5894982"/>
      <value value="4536573"/>
      <value value="5575905"/>
      <value value="4252052"/>
      <value value="5313763"/>
      <value value="6103579"/>
      <value value="4150886"/>
      <value value="5576063"/>
      <value value="9504504"/>
      <value value="7160960"/>
      <value value="3957602"/>
      <value value="6786098"/>
      <value value="2472044"/>
      <value value="8639938"/>
      <value value="5418567"/>
      <value value="1172382"/>
      <value value="8656860"/>
      <value value="841488"/>
      <value value="8205214"/>
      <value value="1267761"/>
      <value value="6145447"/>
      <value value="2199919"/>
      <value value="5280856"/>
      <value value="9072835"/>
      <value value="510756"/>
      <value value="5098617"/>
      <value value="6789222"/>
      <value value="2356388"/>
      <value value="9086281"/>
      <value value="8175415"/>
      <value value="2900793"/>
      <value value="6591306"/>
      <value value="7689478"/>
      <value value="7350607"/>
      <value value="6443327"/>
      <value value="704376"/>
      <value value="9052422"/>
      <value value="7775265"/>
      <value value="8884616"/>
      <value value="6286366"/>
      <value value="144851"/>
      <value value="9570201"/>
      <value value="7481267"/>
      <value value="5108992"/>
      <value value="3679474"/>
      <value value="9143627"/>
      <value value="9998951"/>
      <value value="4888623"/>
      <value value="5397076"/>
      <value value="7439676"/>
      <value value="8610507"/>
      <value value="1863531"/>
      <value value="1323016"/>
      <value value="4521465"/>
      <value value="4263936"/>
      <value value="7661577"/>
      <value value="2075444"/>
      <value value="8822503"/>
      <value value="9662316"/>
      <value value="2973335"/>
      <value value="7071415"/>
      <value value="8159649"/>
      <value value="9283375"/>
      <value value="1131087"/>
      <value value="9303439"/>
      <value value="8104401"/>
      <value value="9743829"/>
      <value value="8306635"/>
      <value value="5731223"/>
      <value value="4121385"/>
      <value value="2869347"/>
      <value value="3920902"/>
      <value value="6167083"/>
      <value value="7419525"/>
      <value value="5908477"/>
      <value value="6064562"/>
      <value value="6424885"/>
      <value value="6969564"/>
      <value value="3927848"/>
      <value value="2358372"/>
      <value value="3251248"/>
      <value value="1751034"/>
      <value value="8468127"/>
      <value value="8353018"/>
      <value value="951349"/>
      <value value="8542770"/>
      <value value="6194462"/>
      <value value="4018656"/>
      <value value="7065348"/>
      <value value="3097042"/>
      <value value="4195395"/>
      <value value="5250943"/>
      <value value="7240650"/>
      <value value="9608548"/>
      <value value="5108265"/>
      <value value="4593450"/>
      <value value="5425759"/>
      <value value="3676105"/>
      <value value="1692371"/>
      <value value="1706692"/>
      <value value="1757632"/>
      <value value="1092206"/>
      <value value="8437560"/>
      <value value="3961722"/>
      <value value="1975323"/>
      <value value="9185287"/>
      <value value="2335293"/>
      <value value="5763230"/>
      <value value="8788200"/>
      <value value="3497859"/>
      <value value="9512182"/>
      <value value="8112497"/>
      <value value="4892056"/>
      <value value="4585252"/>
      <value value="606525"/>
      <value value="5318331"/>
      <value value="6177637"/>
      <value value="8993398"/>
      <value value="3020530"/>
      <value value="3816854"/>
      <value value="5490402"/>
      <value value="3641237"/>
      <value value="7580938"/>
      <value value="5825082"/>
      <value value="6926254"/>
      <value value="2174499"/>
      <value value="6253317"/>
      <value value="8119953"/>
      <value value="6451779"/>
      <value value="6570102"/>
      <value value="1504805"/>
      <value value="5223626"/>
      <value value="2235675"/>
      <value value="3813760"/>
      <value value="6440646"/>
      <value value="3061320"/>
      <value value="5698975"/>
      <value value="6745788"/>
      <value value="9896101"/>
      <value value="7185109"/>
      <value value="1127408"/>
      <value value="7284052"/>
      <value value="2706810"/>
      <value value="4217887"/>
      <value value="7958121"/>
      <value value="537616"/>
      <value value="8762620"/>
      <value value="3687811"/>
      <value value="5269781"/>
      <value value="7582593"/>
      <value value="9611906"/>
      <value value="1196910"/>
      <value value="1667805"/>
      <value value="4475446"/>
      <value value="9849161"/>
      <value value="7272361"/>
      <value value="2613494"/>
      <value value="4529989"/>
      <value value="3051819"/>
      <value value="3320541"/>
      <value value="3801624"/>
      <value value="1993259"/>
      <value value="598272"/>
      <value value="6551119"/>
      <value value="3631792"/>
      <value value="9552753"/>
      <value value="3309648"/>
      <value value="2038147"/>
      <value value="3679627"/>
      <value value="8911977"/>
      <value value="2081431"/>
      <value value="5467578"/>
      <value value="7263638"/>
      <value value="3764122"/>
      <value value="8585034"/>
      <value value="5689008"/>
      <value value="7553471"/>
      <value value="8592865"/>
      <value value="6630288"/>
      <value value="3252194"/>
      <value value="8272977"/>
      <value value="8910981"/>
      <value value="3092377"/>
      <value value="7643090"/>
      <value value="4750985"/>
      <value value="3140520"/>
      <value value="6814768"/>
      <value value="4551104"/>
      <value value="9755734"/>
      <value value="6466784"/>
      <value value="6872930"/>
      <value value="2957058"/>
      <value value="4555390"/>
      <value value="6873632"/>
      <value value="518204"/>
      <value value="4727494"/>
      <value value="5754016"/>
      <value value="1728199"/>
      <value value="6771342"/>
      <value value="439179"/>
      <value value="4388049"/>
      <value value="1929255"/>
      <value value="1649138"/>
      <value value="2962770"/>
      <value value="1111983"/>
      <value value="2703915"/>
      <value value="7494705"/>
      <value value="4517580"/>
      <value value="9754736"/>
      <value value="6707959"/>
      <value value="6713379"/>
      <value value="5215926"/>
      <value value="5112795"/>
      <value value="5416889"/>
      <value value="558875"/>
      <value value="1108435"/>
      <value value="6098286"/>
      <value value="8691869"/>
      <value value="5473397"/>
      <value value="6503758"/>
      <value value="6457319"/>
      <value value="5745239"/>
      <value value="5342009"/>
      <value value="208641"/>
      <value value="9583692"/>
      <value value="8857210"/>
      <value value="2918482"/>
      <value value="9093732"/>
      <value value="7697365"/>
      <value value="4595666"/>
      <value value="8088404"/>
      <value value="7374522"/>
      <value value="8002833"/>
      <value value="4623441"/>
      <value value="3060095"/>
      <value value="6672145"/>
      <value value="6148617"/>
      <value value="65226"/>
      <value value="8339910"/>
      <value value="174343"/>
      <value value="1779694"/>
      <value value="7121344"/>
      <value value="8945732"/>
      <value value="2731203"/>
      <value value="798810"/>
      <value value="3055577"/>
      <value value="994794"/>
      <value value="4971717"/>
      <value value="1926233"/>
      <value value="5294506"/>
      <value value="8451221"/>
      <value value="7657904"/>
      <value value="435498"/>
      <value value="4522413"/>
      <value value="7928346"/>
      <value value="7553806"/>
      <value value="8590064"/>
      <value value="1290326"/>
      <value value="2713825"/>
      <value value="5793048"/>
      <value value="9249222"/>
      <value value="4690394"/>
      <value value="5868023"/>
      <value value="6853404"/>
      <value value="7999967"/>
      <value value="4532559"/>
      <value value="8454654"/>
      <value value="8978119"/>
      <value value="6887693"/>
      <value value="8704741"/>
      <value value="7002241"/>
      <value value="2322006"/>
      <value value="1057963"/>
      <value value="7293172"/>
      <value value="7291218"/>
      <value value="4462904"/>
      <value value="1797012"/>
      <value value="4969353"/>
      <value value="5103119"/>
      <value value="2224372"/>
      <value value="3382301"/>
      <value value="9993664"/>
      <value value="4952808"/>
      <value value="7939298"/>
      <value value="9642376"/>
      <value value="7485418"/>
      <value value="8220757"/>
      <value value="5092254"/>
      <value value="7084855"/>
      <value value="7148286"/>
      <value value="2492794"/>
      <value value="4872811"/>
      <value value="6099068"/>
      <value value="3664363"/>
      <value value="9097628"/>
      <value value="177750"/>
      <value value="6594114"/>
      <value value="592890"/>
      <value value="915257"/>
      <value value="9806137"/>
      <value value="2123792"/>
      <value value="5534657"/>
      <value value="4204191"/>
      <value value="6938743"/>
      <value value="2817075"/>
      <value value="6438732"/>
      <value value="2396842"/>
      <value value="1833068"/>
      <value value="3650822"/>
      <value value="6430924"/>
      <value value="3135325"/>
      <value value="5264773"/>
      <value value="1030343"/>
      <value value="9935608"/>
      <value value="7364853"/>
      <value value="8645470"/>
      <value value="3255478"/>
      <value value="4549086"/>
      <value value="5278805"/>
      <value value="7899613"/>
      <value value="1465774"/>
      <value value="4293676"/>
      <value value="6543204"/>
      <value value="6618805"/>
      <value value="7258239"/>
      <value value="7522583"/>
      <value value="879432"/>
      <value value="4398567"/>
      <value value="3825834"/>
      <value value="4138324"/>
      <value value="3990944"/>
      <value value="5366360"/>
      <value value="3629947"/>
      <value value="3430145"/>
      <value value="6468398"/>
      <value value="3523334"/>
      <value value="1652853"/>
      <value value="1379428"/>
      <value value="833897"/>
      <value value="922268"/>
      <value value="6402730"/>
      <value value="6813305"/>
      <value value="6162518"/>
      <value value="2860263"/>
      <value value="3535726"/>
      <value value="6940795"/>
      <value value="2309773"/>
      <value value="715005"/>
      <value value="8952285"/>
      <value value="5807792"/>
      <value value="8172651"/>
      <value value="6125963"/>
      <value value="5296833"/>
      <value value="2357732"/>
      <value value="6818083"/>
      <value value="3826973"/>
      <value value="3107720"/>
      <value value="787990"/>
      <value value="4533268"/>
      <value value="542976"/>
      <value value="8107658"/>
      <value value="2503748"/>
      <value value="3914133"/>
      <value value="6148845"/>
      <value value="883795"/>
      <value value="8166559"/>
      <value value="5602568"/>
      <value value="1317389"/>
      <value value="48318"/>
      <value value="4246759"/>
      <value value="2635009"/>
      <value value="4772354"/>
      <value value="4272825"/>
      <value value="1997632"/>
      <value value="9446574"/>
      <value value="1075615"/>
      <value value="5520478"/>
      <value value="9882101"/>
      <value value="6668055"/>
      <value value="8945066"/>
      <value value="3666979"/>
      <value value="5699081"/>
      <value value="6428483"/>
      <value value="1560431"/>
      <value value="5875788"/>
      <value value="6536208"/>
      <value value="5695868"/>
      <value value="1207229"/>
      <value value="11415"/>
      <value value="3959657"/>
      <value value="3793572"/>
      <value value="258920"/>
      <value value="1619299"/>
      <value value="826149"/>
      <value value="2481643"/>
      <value value="4106446"/>
      <value value="3438701"/>
      <value value="3958267"/>
      <value value="5703359"/>
      <value value="95660"/>
      <value value="3872924"/>
      <value value="1281387"/>
      <value value="1381596"/>
      <value value="7927640"/>
      <value value="3534064"/>
      <value value="4097585"/>
      <value value="3673751"/>
      <value value="1395821"/>
      <value value="1611276"/>
      <value value="1237638"/>
      <value value="1499350"/>
      <value value="126671"/>
      <value value="4821356"/>
      <value value="4019857"/>
      <value value="4416456"/>
      <value value="1568099"/>
      <value value="3917534"/>
      <value value="989578"/>
      <value value="9333656"/>
      <value value="476842"/>
      <value value="3136747"/>
      <value value="228998"/>
      <value value="3733469"/>
      <value value="1688276"/>
      <value value="8453862"/>
      <value value="3052057"/>
      <value value="1318246"/>
      <value value="172418"/>
      <value value="8690162"/>
      <value value="5087838"/>
      <value value="1930573"/>
      <value value="527652"/>
      <value value="2606232"/>
      <value value="4651871"/>
      <value value="7396100"/>
      <value value="4685150"/>
      <value value="8318912"/>
      <value value="5179521"/>
      <value value="2970571"/>
      <value value="6862005"/>
      <value value="8199596"/>
      <value value="2938905"/>
      <value value="3281024"/>
      <value value="8040268"/>
      <value value="1233138"/>
      <value value="2243149"/>
      <value value="2477072"/>
      <value value="936296"/>
      <value value="7547229"/>
      <value value="3568417"/>
      <value value="9574172"/>
      <value value="2544266"/>
      <value value="3751674"/>
      <value value="397464"/>
      <value value="2101185"/>
      <value value="3913245"/>
      <value value="2330252"/>
      <value value="9102031"/>
      <value value="8052433"/>
      <value value="5541191"/>
      <value value="9577047"/>
      <value value="8199497"/>
      <value value="4645503"/>
      <value value="3427608"/>
      <value value="7620463"/>
      <value value="4804917"/>
      <value value="7158049"/>
      <value value="7679496"/>
      <value value="5834047"/>
      <value value="9528948"/>
      <value value="3022150"/>
      <value value="5638242"/>
      <value value="7248909"/>
      <value value="2403187"/>
      <value value="7767676"/>
      <value value="879365"/>
      <value value="4854691"/>
      <value value="1397267"/>
      <value value="53542"/>
      <value value="7915363"/>
      <value value="1086358"/>
      <value value="3680439"/>
      <value value="4404274"/>
      <value value="4332820"/>
      <value value="4579512"/>
      <value value="5231709"/>
      <value value="3183315"/>
      <value value="437800"/>
      <value value="2346676"/>
      <value value="6453289"/>
      <value value="112276"/>
      <value value="126373"/>
      <value value="9204255"/>
      <value value="9419876"/>
      <value value="7845704"/>
      <value value="6911325"/>
      <value value="6735588"/>
      <value value="7714831"/>
      <value value="1930675"/>
      <value value="3328294"/>
      <value value="2082060"/>
      <value value="7628480"/>
      <value value="879724"/>
      <value value="9208144"/>
      <value value="190158"/>
      <value value="9117154"/>
      <value value="8297572"/>
      <value value="1766504"/>
      <value value="9775791"/>
      <value value="7829496"/>
      <value value="1657456"/>
      <value value="4610755"/>
      <value value="3364753"/>
      <value value="3589412"/>
      <value value="9646488"/>
      <value value="3258385"/>
      <value value="1839694"/>
      <value value="6559753"/>
      <value value="9847734"/>
      <value value="6060727"/>
      <value value="1482069"/>
      <value value="9713030"/>
      <value value="1977784"/>
      <value value="5800700"/>
      <value value="8200773"/>
      <value value="839448"/>
      <value value="6319759"/>
      <value value="3615295"/>
      <value value="4040063"/>
      <value value="7873338"/>
      <value value="9024093"/>
      <value value="8604634"/>
      <value value="4668976"/>
      <value value="5155648"/>
      <value value="3792020"/>
      <value value="5194249"/>
      <value value="2669506"/>
      <value value="897610"/>
      <value value="7986289"/>
      <value value="4482519"/>
      <value value="8044455"/>
      <value value="595538"/>
      <value value="5040490"/>
      <value value="3118977"/>
      <value value="2785502"/>
      <value value="2309505"/>
      <value value="4943153"/>
      <value value="2574889"/>
      <value value="2468570"/>
      <value value="8842282"/>
      <value value="3358295"/>
      <value value="9536079"/>
      <value value="1904462"/>
      <value value="1996915"/>
      <value value="9447707"/>
      <value value="8548689"/>
      <value value="788452"/>
      <value value="7399820"/>
      <value value="8505538"/>
      <value value="5405534"/>
      <value value="4291250"/>
      <value value="8276000"/>
      <value value="6701628"/>
      <value value="1916566"/>
      <value value="2291860"/>
      <value value="3828635"/>
      <value value="6431509"/>
      <value value="3902169"/>
      <value value="1787310"/>
      <value value="920767"/>
      <value value="9265480"/>
      <value value="4144343"/>
      <value value="8678714"/>
      <value value="9939846"/>
      <value value="9746019"/>
      <value value="8946996"/>
      <value value="7527768"/>
      <value value="6159296"/>
      <value value="252968"/>
      <value value="8859820"/>
      <value value="9346511"/>
      <value value="864547"/>
      <value value="8737987"/>
      <value value="2802370"/>
      <value value="9905472"/>
      <value value="1279343"/>
      <value value="2659464"/>
      <value value="4891528"/>
      <value value="7160968"/>
      <value value="8070117"/>
      <value value="1952855"/>
      <value value="2083709"/>
      <value value="3888268"/>
      <value value="6928610"/>
      <value value="2582653"/>
      <value value="4305527"/>
      <value value="4499319"/>
      <value value="9128636"/>
      <value value="3029840"/>
      <value value="2036719"/>
      <value value="4739781"/>
      <value value="2503449"/>
      <value value="1762025"/>
      <value value="2790591"/>
      <value value="3518316"/>
      <value value="9226141"/>
      <value value="7892820"/>
      <value value="2868422"/>
      <value value="2576198"/>
      <value value="8177203"/>
      <value value="859205"/>
      <value value="9281721"/>
      <value value="7910615"/>
      <value value="706827"/>
      <value value="5661663"/>
      <value value="2037172"/>
      <value value="6848633"/>
      <value value="8046971"/>
      <value value="770736"/>
      <value value="5781654"/>
      <value value="3551179"/>
      <value value="7925362"/>
      <value value="5324029"/>
      <value value="5147081"/>
      <value value="3532156"/>
      <value value="7502499"/>
      <value value="4354541"/>
      <value value="2199849"/>
      <value value="2523704"/>
      <value value="897353"/>
      <value value="7282112"/>
      <value value="2634631"/>
      <value value="9542303"/>
      <value value="124112"/>
      <value value="9207954"/>
      <value value="435813"/>
      <value value="8675056"/>
      <value value="768037"/>
      <value value="3078670"/>
      <value value="3682279"/>
      <value value="9493883"/>
      <value value="3500125"/>
      <value value="186207"/>
      <value value="461825"/>
      <value value="7247280"/>
      <value value="7856620"/>
      <value value="7125522"/>
      <value value="8455539"/>
      <value value="6472662"/>
      <value value="9595050"/>
      <value value="8790328"/>
      <value value="5111752"/>
      <value value="877765"/>
      <value value="3580877"/>
      <value value="3995669"/>
      <value value="8025562"/>
      <value value="2506911"/>
      <value value="8996496"/>
      <value value="1567828"/>
      <value value="7191017"/>
      <value value="5527958"/>
      <value value="3063963"/>
      <value value="1340688"/>
      <value value="7371046"/>
      <value value="4827404"/>
      <value value="2671684"/>
      <value value="5056766"/>
      <value value="8763821"/>
      <value value="4879039"/>
      <value value="1035094"/>
      <value value="1010047"/>
      <value value="2662019"/>
      <value value="4124053"/>
      <value value="7620425"/>
      <value value="6274351"/>
      <value value="2831251"/>
      <value value="7906792"/>
      <value value="2185591"/>
      <value value="5117484"/>
      <value value="5622779"/>
      <value value="5933757"/>
      <value value="3228050"/>
      <value value="7437800"/>
      <value value="5326640"/>
      <value value="8983741"/>
      <value value="9869711"/>
      <value value="5310315"/>
      <value value="4425269"/>
      <value value="883922"/>
      <value value="697922"/>
      <value value="8526223"/>
      <value value="3029022"/>
      <value value="1323932"/>
      <value value="4077073"/>
      <value value="1969880"/>
      <value value="8084642"/>
      <value value="350829"/>
      <value value="838433"/>
      <value value="2699709"/>
      <value value="380268"/>
      <value value="8700885"/>
      <value value="7745629"/>
      <value value="497482"/>
      <value value="7136648"/>
      <value value="1905071"/>
      <value value="6796417"/>
      <value value="7392836"/>
      <value value="7401986"/>
      <value value="9672131"/>
      <value value="5594274"/>
      <value value="2811614"/>
      <value value="7538279"/>
      <value value="1047312"/>
      <value value="135711"/>
      <value value="4272721"/>
      <value value="325684"/>
      <value value="9624625"/>
      <value value="9431295"/>
      <value value="3112689"/>
      <value value="6057316"/>
      <value value="3398875"/>
      <value value="1762616"/>
      <value value="1311462"/>
      <value value="9453623"/>
      <value value="2397004"/>
      <value value="6354233"/>
      <value value="9061373"/>
      <value value="293392"/>
      <value value="8626037"/>
      <value value="674046"/>
      <value value="2115978"/>
      <value value="8448947"/>
      <value value="8236534"/>
      <value value="7243907"/>
      <value value="487218"/>
      <value value="4188590"/>
      <value value="9303454"/>
      <value value="8590131"/>
      <value value="5378191"/>
      <value value="1061387"/>
      <value value="2846853"/>
      <value value="3797482"/>
      <value value="866286"/>
      <value value="4362495"/>
      <value value="1564310"/>
      <value value="4703377"/>
      <value value="6823409"/>
      <value value="7348713"/>
      <value value="3701329"/>
      <value value="7853973"/>
      <value value="2391638"/>
      <value value="1903785"/>
      <value value="9921192"/>
      <value value="8312087"/>
      <value value="8096201"/>
      <value value="4956260"/>
      <value value="8556024"/>
      <value value="3464038"/>
      <value value="7203948"/>
      <value value="4886913"/>
      <value value="474411"/>
      <value value="5244518"/>
      <value value="1716786"/>
      <value value="2441606"/>
      <value value="3420556"/>
      <value value="2920065"/>
      <value value="4464695"/>
      <value value="8168483"/>
      <value value="1445234"/>
      <value value="9281101"/>
      <value value="5747846"/>
      <value value="7746422"/>
      <value value="3588272"/>
      <value value="3728119"/>
      <value value="2155738"/>
      <value value="5219210"/>
      <value value="7800401"/>
      <value value="777420"/>
      <value value="1393495"/>
      <value value="1134538"/>
      <value value="3527666"/>
      <value value="1338014"/>
      <value value="6736216"/>
      <value value="9233048"/>
      <value value="6910209"/>
      <value value="6365613"/>
      <value value="7256434"/>
      <value value="724087"/>
      <value value="4959160"/>
      <value value="2101413"/>
      <value value="4510128"/>
      <value value="293866"/>
      <value value="22653"/>
      <value value="3007598"/>
      <value value="2926386"/>
      <value value="5870803"/>
      <value value="5508469"/>
      <value value="1436899"/>
      <value value="3770932"/>
      <value value="1114118"/>
      <value value="3205424"/>
      <value value="6498553"/>
      <value value="7735822"/>
      <value value="5270258"/>
      <value value="8663749"/>
      <value value="7373754"/>
      <value value="1967409"/>
      <value value="9581173"/>
      <value value="3086640"/>
      <value value="6883068"/>
      <value value="6746804"/>
      <value value="823060"/>
      <value value="6047091"/>
      <value value="6568401"/>
      <value value="8072167"/>
      <value value="5247921"/>
      <value value="8397255"/>
      <value value="6689774"/>
      <value value="8127471"/>
      <value value="8912887"/>
      <value value="2199485"/>
      <value value="205235"/>
      <value value="9753689"/>
      <value value="3957468"/>
      <value value="394875"/>
      <value value="4152435"/>
      <value value="7914537"/>
      <value value="6219832"/>
      <value value="9233849"/>
      <value value="8219744"/>
      <value value="6212559"/>
      <value value="9663273"/>
      <value value="1148056"/>
      <value value="22244"/>
      <value value="3772271"/>
      <value value="3529324"/>
      <value value="8435940"/>
      <value value="5834572"/>
      <value value="8543035"/>
      <value value="7644751"/>
      <value value="5560521"/>
      <value value="4447325"/>
      <value value="3524283"/>
      <value value="6830108"/>
      <value value="4073128"/>
      <value value="1896137"/>
      <value value="5403483"/>
      <value value="1979301"/>
      <value value="4993615"/>
      <value value="449668"/>
      <value value="8388430"/>
      <value value="7074549"/>
      <value value="3496408"/>
      <value value="3829697"/>
      <value value="8557340"/>
      <value value="6631526"/>
      <value value="7299030"/>
      <value value="8916847"/>
      <value value="1806818"/>
      <value value="807775"/>
      <value value="4778417"/>
      <value value="8330548"/>
      <value value="7449399"/>
      <value value="8416682"/>
      <value value="9133911"/>
      <value value="2274722"/>
      <value value="3815123"/>
      <value value="4115504"/>
      <value value="8753012"/>
      <value value="1249284"/>
      <value value="808060"/>
      <value value="6536175"/>
      <value value="8941651"/>
      <value value="9837424"/>
      <value value="2465869"/>
      <value value="64783"/>
      <value value="2126472"/>
      <value value="1558238"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param_policy">
      <value value="&quot;StageCal None&quot;"/>
      <value value="&quot;StageCal_1&quot;"/>
      <value value="&quot;StageCal_1b&quot;"/>
      <value value="&quot;StageCal_2&quot;"/>
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
      <value value="0.25"/>
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
  <experiment name="210222_R" repetitions="1" runMetricsEveryStep="false">
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
      <value value="9678787"/>
      <value value="9676644"/>
      <value value="6295136"/>
      <value value="9709519"/>
      <value value="1283760"/>
      <value value="2700663"/>
      <value value="9430240"/>
      <value value="5184395"/>
      <value value="1718452"/>
      <value value="3761002"/>
      <value value="4044220"/>
      <value value="4745269"/>
      <value value="2122841"/>
      <value value="5050363"/>
      <value value="5267812"/>
      <value value="8004820"/>
      <value value="3734113"/>
      <value value="2057604"/>
      <value value="3583564"/>
      <value value="93352"/>
      <value value="6335523"/>
      <value value="2326451"/>
      <value value="9772107"/>
      <value value="2751822"/>
      <value value="9531991"/>
      <value value="6267269"/>
      <value value="5493545"/>
      <value value="8398160"/>
      <value value="6857654"/>
      <value value="1142111"/>
      <value value="2922723"/>
      <value value="3748058"/>
      <value value="3102542"/>
      <value value="5608439"/>
      <value value="4786596"/>
      <value value="7439743"/>
      <value value="1581532"/>
      <value value="3022971"/>
      <value value="3897131"/>
      <value value="5304307"/>
      <value value="2258847"/>
      <value value="9893698"/>
      <value value="9172206"/>
      <value value="4627604"/>
      <value value="9335121"/>
      <value value="7630641"/>
      <value value="4973705"/>
      <value value="6504610"/>
      <value value="6725896"/>
      <value value="8002030"/>
      <value value="9931178"/>
      <value value="2961648"/>
      <value value="6836632"/>
      <value value="5278647"/>
      <value value="6612254"/>
      <value value="808855"/>
      <value value="6808283"/>
      <value value="2725355"/>
      <value value="3106991"/>
      <value value="412288"/>
      <value value="3634779"/>
      <value value="3609788"/>
      <value value="4237332"/>
      <value value="2323364"/>
      <value value="9438840"/>
      <value value="7671890"/>
      <value value="3227604"/>
      <value value="9238399"/>
      <value value="2125188"/>
      <value value="5756532"/>
      <value value="8265876"/>
      <value value="8639621"/>
      <value value="62760"/>
      <value value="2134938"/>
      <value value="4019785"/>
      <value value="5741457"/>
      <value value="6947148"/>
      <value value="9321058"/>
      <value value="4051021"/>
      <value value="7066204"/>
      <value value="7005386"/>
      <value value="7755598"/>
      <value value="4727672"/>
      <value value="1838985"/>
      <value value="6620055"/>
      <value value="3052863"/>
      <value value="6484492"/>
      <value value="3948474"/>
      <value value="1357701"/>
      <value value="8899420"/>
      <value value="6841481"/>
      <value value="2780726"/>
      <value value="4177805"/>
      <value value="4781440"/>
      <value value="8324125"/>
      <value value="7661063"/>
      <value value="1640268"/>
      <value value="2052746"/>
      <value value="9189095"/>
      <value value="2410235"/>
      <value value="5963600"/>
      <value value="4633158"/>
      <value value="5057373"/>
      <value value="5094349"/>
      <value value="1685886"/>
      <value value="8945439"/>
      <value value="4181172"/>
      <value value="9447935"/>
      <value value="6213798"/>
      <value value="942303"/>
      <value value="3314314"/>
      <value value="7760553"/>
      <value value="1039313"/>
      <value value="5753467"/>
      <value value="6740212"/>
      <value value="408722"/>
      <value value="2510956"/>
      <value value="8307449"/>
      <value value="6227318"/>
      <value value="1194313"/>
      <value value="1041541"/>
      <value value="3269597"/>
      <value value="8553364"/>
      <value value="1131101"/>
      <value value="7233026"/>
      <value value="5704027"/>
      <value value="5844836"/>
      <value value="7042750"/>
      <value value="3309225"/>
      <value value="5896615"/>
      <value value="3807887"/>
      <value value="2889504"/>
      <value value="1661658"/>
      <value value="2971675"/>
      <value value="2453414"/>
      <value value="8849175"/>
      <value value="4045351"/>
      <value value="7672243"/>
      <value value="1191404"/>
      <value value="771124"/>
      <value value="7724216"/>
      <value value="5988584"/>
      <value value="3076125"/>
      <value value="4857086"/>
      <value value="1059679"/>
      <value value="99024"/>
      <value value="8446280"/>
      <value value="7696835"/>
      <value value="3399931"/>
      <value value="3782908"/>
      <value value="4588961"/>
      <value value="3715678"/>
      <value value="3197412"/>
      <value value="4770267"/>
      <value value="8818929"/>
      <value value="858592"/>
      <value value="3813596"/>
      <value value="702842"/>
      <value value="8837764"/>
      <value value="7311939"/>
      <value value="8990591"/>
      <value value="7480150"/>
      <value value="1533132"/>
      <value value="986933"/>
      <value value="7866570"/>
      <value value="1926293"/>
      <value value="6681180"/>
      <value value="1012782"/>
      <value value="7782034"/>
      <value value="8513904"/>
      <value value="4938300"/>
      <value value="7585318"/>
      <value value="8114306"/>
      <value value="9517128"/>
      <value value="5152116"/>
      <value value="7075996"/>
      <value value="8952144"/>
      <value value="801733"/>
      <value value="9303373"/>
      <value value="1209603"/>
      <value value="2022321"/>
      <value value="1627349"/>
      <value value="7006817"/>
      <value value="7062053"/>
      <value value="8552684"/>
      <value value="7173206"/>
      <value value="9215824"/>
      <value value="989539"/>
      <value value="5719124"/>
      <value value="1885367"/>
      <value value="4262333"/>
      <value value="302648"/>
      <value value="8396866"/>
      <value value="1793591"/>
      <value value="6185978"/>
      <value value="1950752"/>
      <value value="4151105"/>
      <value value="8595068"/>
      <value value="1034915"/>
      <value value="6018415"/>
      <value value="1369433"/>
      <value value="7325598"/>
      <value value="2481898"/>
      <value value="5516971"/>
      <value value="6432773"/>
      <value value="3648679"/>
      <value value="3949225"/>
      <value value="7845302"/>
      <value value="1718047"/>
      <value value="7011128"/>
      <value value="687365"/>
      <value value="9746514"/>
      <value value="638902"/>
      <value value="7807340"/>
      <value value="4768642"/>
      <value value="9037162"/>
      <value value="6479193"/>
      <value value="3053388"/>
      <value value="7759636"/>
      <value value="8171441"/>
      <value value="7221451"/>
      <value value="7791476"/>
      <value value="5159683"/>
      <value value="3153806"/>
      <value value="3899298"/>
      <value value="4997116"/>
      <value value="3262953"/>
      <value value="1922943"/>
      <value value="5162009"/>
      <value value="4571303"/>
      <value value="5195649"/>
      <value value="7705146"/>
      <value value="4695957"/>
      <value value="3573094"/>
      <value value="8571333"/>
      <value value="5767004"/>
      <value value="1018105"/>
      <value value="2057270"/>
      <value value="6251180"/>
      <value value="3662414"/>
      <value value="6957610"/>
      <value value="8005407"/>
      <value value="5651687"/>
      <value value="1123898"/>
      <value value="4580490"/>
      <value value="8768874"/>
      <value value="5313175"/>
      <value value="5751633"/>
      <value value="2286340"/>
      <value value="1721591"/>
      <value value="1008637"/>
      <value value="3921096"/>
      <value value="8266891"/>
      <value value="7078463"/>
      <value value="3974562"/>
      <value value="4579183"/>
      <value value="8144516"/>
      <value value="7273903"/>
      <value value="2205175"/>
      <value value="2549650"/>
      <value value="220106"/>
      <value value="6332402"/>
      <value value="6543423"/>
      <value value="6503597"/>
      <value value="1286161"/>
      <value value="5556230"/>
      <value value="3903934"/>
      <value value="4061241"/>
      <value value="1328975"/>
      <value value="3875135"/>
      <value value="6213135"/>
      <value value="4704932"/>
      <value value="2651787"/>
      <value value="4734083"/>
      <value value="995747"/>
      <value value="4596061"/>
      <value value="9407515"/>
      <value value="7935430"/>
      <value value="706924"/>
      <value value="3972383"/>
      <value value="7742897"/>
      <value value="9622133"/>
      <value value="430985"/>
      <value value="501933"/>
      <value value="6851443"/>
      <value value="6551085"/>
      <value value="77051"/>
      <value value="116501"/>
      <value value="7386318"/>
      <value value="1421826"/>
      <value value="1422117"/>
      <value value="2298267"/>
      <value value="4372933"/>
      <value value="2091453"/>
      <value value="9319538"/>
      <value value="6525680"/>
      <value value="9833322"/>
      <value value="3674077"/>
      <value value="4972082"/>
      <value value="6618015"/>
      <value value="9508274"/>
      <value value="2546336"/>
      <value value="2131273"/>
      <value value="1856317"/>
      <value value="6459122"/>
      <value value="5300290"/>
      <value value="9777896"/>
      <value value="9995179"/>
      <value value="2387446"/>
      <value value="7601422"/>
      <value value="4113421"/>
      <value value="6183824"/>
      <value value="3309771"/>
      <value value="3958404"/>
      <value value="2963605"/>
      <value value="2631852"/>
      <value value="462030"/>
      <value value="6744031"/>
      <value value="7505880"/>
      <value value="5917683"/>
      <value value="2247090"/>
      <value value="4193961"/>
      <value value="2248239"/>
      <value value="8319344"/>
      <value value="1430739"/>
      <value value="5229096"/>
      <value value="6722863"/>
      <value value="9086637"/>
      <value value="34482"/>
      <value value="5955671"/>
      <value value="641440"/>
      <value value="9379203"/>
      <value value="926271"/>
      <value value="6667728"/>
      <value value="9709791"/>
      <value value="6087636"/>
      <value value="4661563"/>
      <value value="3635261"/>
      <value value="730206"/>
      <value value="5874859"/>
      <value value="4226621"/>
      <value value="7114114"/>
      <value value="6415243"/>
      <value value="74347"/>
      <value value="8163112"/>
      <value value="7374261"/>
      <value value="5619657"/>
      <value value="9381328"/>
      <value value="7801911"/>
      <value value="5370168"/>
      <value value="6702201"/>
      <value value="8071418"/>
      <value value="1300676"/>
      <value value="3548518"/>
      <value value="3775507"/>
      <value value="5989989"/>
      <value value="2330683"/>
      <value value="4444954"/>
      <value value="7448662"/>
      <value value="6783064"/>
      <value value="9895614"/>
      <value value="8848843"/>
      <value value="8330774"/>
      <value value="135942"/>
      <value value="7113212"/>
      <value value="4104290"/>
      <value value="3715442"/>
      <value value="8915412"/>
      <value value="6514672"/>
      <value value="4658913"/>
      <value value="9487313"/>
      <value value="8829250"/>
      <value value="9001863"/>
      <value value="9292677"/>
      <value value="1916060"/>
      <value value="2078215"/>
      <value value="7710724"/>
      <value value="6285583"/>
      <value value="4320618"/>
      <value value="5895010"/>
      <value value="587230"/>
      <value value="3895229"/>
      <value value="7287619"/>
      <value value="5781885"/>
      <value value="651176"/>
      <value value="5150575"/>
      <value value="9674461"/>
      <value value="2655390"/>
      <value value="345268"/>
      <value value="8901340"/>
      <value value="1223314"/>
      <value value="101430"/>
      <value value="5425852"/>
      <value value="7472030"/>
      <value value="6811974"/>
      <value value="1570341"/>
      <value value="5342546"/>
      <value value="2270099"/>
      <value value="2226197"/>
      <value value="3437048"/>
      <value value="6908350"/>
      <value value="7570561"/>
      <value value="8988677"/>
      <value value="3733174"/>
      <value value="8015132"/>
      <value value="8439283"/>
      <value value="2065462"/>
      <value value="6308011"/>
      <value value="9707644"/>
      <value value="8313203"/>
      <value value="8210504"/>
      <value value="4945636"/>
      <value value="6894964"/>
      <value value="9161524"/>
      <value value="6000146"/>
      <value value="9509366"/>
      <value value="832479"/>
      <value value="3604217"/>
      <value value="959257"/>
      <value value="4064640"/>
      <value value="4930452"/>
      <value value="4265772"/>
      <value value="8965808"/>
      <value value="1388832"/>
      <value value="8895384"/>
      <value value="6870628"/>
      <value value="4117898"/>
      <value value="3851876"/>
      <value value="2401363"/>
      <value value="6771530"/>
      <value value="4829995"/>
      <value value="7478084"/>
      <value value="3752894"/>
      <value value="6326412"/>
      <value value="4443205"/>
      <value value="8655589"/>
      <value value="8149913"/>
      <value value="3754764"/>
      <value value="6693068"/>
      <value value="3010401"/>
      <value value="9972320"/>
      <value value="3503353"/>
      <value value="1400983"/>
      <value value="6293059"/>
      <value value="4946213"/>
      <value value="360679"/>
      <value value="9915846"/>
      <value value="8950765"/>
      <value value="2830393"/>
      <value value="9116869"/>
      <value value="7244632"/>
      <value value="512072"/>
      <value value="2771142"/>
      <value value="7601149"/>
      <value value="4816908"/>
      <value value="5444268"/>
      <value value="8925699"/>
      <value value="3698324"/>
      <value value="9716983"/>
      <value value="691970"/>
      <value value="7028236"/>
      <value value="271409"/>
      <value value="5412382"/>
      <value value="2351619"/>
      <value value="6903587"/>
      <value value="1838180"/>
      <value value="7206051"/>
      <value value="350309"/>
      <value value="7361401"/>
      <value value="1557193"/>
      <value value="8901105"/>
      <value value="1788008"/>
      <value value="9064967"/>
      <value value="1970177"/>
      <value value="2695669"/>
      <value value="2601909"/>
      <value value="3853484"/>
      <value value="8125892"/>
      <value value="6912745"/>
      <value value="9962268"/>
      <value value="3447898"/>
      <value value="6622339"/>
      <value value="819747"/>
      <value value="5854124"/>
      <value value="8518216"/>
      <value value="9375089"/>
      <value value="4048650"/>
      <value value="7791483"/>
      <value value="5757390"/>
      <value value="3064437"/>
      <value value="7174996"/>
      <value value="8473614"/>
      <value value="3749771"/>
      <value value="3181650"/>
      <value value="5590148"/>
      <value value="7625492"/>
      <value value="1496354"/>
      <value value="1601208"/>
      <value value="4883598"/>
      <value value="483586"/>
      <value value="5774938"/>
      <value value="3496192"/>
      <value value="3041485"/>
      <value value="3544588"/>
      <value value="1138622"/>
      <value value="3358820"/>
      <value value="3776481"/>
      <value value="463865"/>
      <value value="3252407"/>
      <value value="718781"/>
      <value value="4524209"/>
      <value value="6418092"/>
      <value value="8462592"/>
      <value value="7192813"/>
      <value value="9302221"/>
      <value value="876148"/>
      <value value="7102977"/>
      <value value="5161201"/>
      <value value="5462691"/>
      <value value="9142914"/>
      <value value="461111"/>
      <value value="5540164"/>
      <value value="8184040"/>
      <value value="7638821"/>
      <value value="2095728"/>
      <value value="5371960"/>
      <value value="7360242"/>
      <value value="2080447"/>
      <value value="7025170"/>
      <value value="3088506"/>
      <value value="8877973"/>
      <value value="6697824"/>
      <value value="8599622"/>
      <value value="5841211"/>
      <value value="373938"/>
      <value value="8379088"/>
      <value value="9326617"/>
      <value value="3022116"/>
      <value value="8225935"/>
      <value value="6174003"/>
      <value value="6109674"/>
      <value value="2044338"/>
      <value value="8623138"/>
      <value value="4807048"/>
      <value value="3787629"/>
      <value value="3313380"/>
      <value value="2299640"/>
      <value value="3942623"/>
      <value value="8287931"/>
      <value value="3863292"/>
      <value value="9209607"/>
      <value value="4199231"/>
      <value value="4157507"/>
      <value value="9191677"/>
      <value value="4252846"/>
      <value value="2294664"/>
      <value value="9080030"/>
      <value value="2823531"/>
      <value value="1845128"/>
      <value value="159776"/>
      <value value="2220705"/>
      <value value="5387584"/>
      <value value="3042768"/>
      <value value="7777103"/>
      <value value="3197984"/>
      <value value="4173251"/>
      <value value="3532264"/>
      <value value="8264651"/>
      <value value="7583848"/>
      <value value="2207465"/>
      <value value="1442621"/>
      <value value="9765560"/>
      <value value="1177258"/>
      <value value="9346419"/>
      <value value="1320724"/>
      <value value="4990400"/>
      <value value="3742456"/>
      <value value="457130"/>
      <value value="4642878"/>
      <value value="7232751"/>
      <value value="4048382"/>
      <value value="8547636"/>
      <value value="3393205"/>
      <value value="1534514"/>
      <value value="5230502"/>
      <value value="5628793"/>
      <value value="8511657"/>
      <value value="2050173"/>
      <value value="5445219"/>
      <value value="7363965"/>
      <value value="5649833"/>
      <value value="1916573"/>
      <value value="5169995"/>
      <value value="6414043"/>
      <value value="7414044"/>
      <value value="7835637"/>
      <value value="5357270"/>
      <value value="1538824"/>
      <value value="1916117"/>
      <value value="6662631"/>
      <value value="5848166"/>
      <value value="349684"/>
      <value value="6043775"/>
      <value value="2610643"/>
      <value value="3043875"/>
      <value value="5242376"/>
      <value value="6687178"/>
      <value value="8423215"/>
      <value value="4508017"/>
      <value value="6380215"/>
      <value value="6111388"/>
      <value value="6521826"/>
      <value value="2386845"/>
      <value value="461492"/>
      <value value="1249736"/>
      <value value="4324136"/>
      <value value="5097060"/>
      <value value="3421497"/>
      <value value="4072165"/>
      <value value="9422549"/>
      <value value="4123436"/>
      <value value="8592061"/>
      <value value="8362283"/>
      <value value="1970207"/>
      <value value="1843910"/>
      <value value="1375122"/>
      <value value="1924733"/>
      <value value="1452625"/>
      <value value="3962990"/>
      <value value="6879316"/>
      <value value="7751241"/>
      <value value="1924800"/>
      <value value="3535413"/>
      <value value="2988935"/>
      <value value="2726133"/>
      <value value="4126010"/>
      <value value="3615399"/>
      <value value="8262285"/>
      <value value="9904919"/>
      <value value="1795316"/>
      <value value="438169"/>
      <value value="996086"/>
      <value value="1158061"/>
      <value value="5272742"/>
      <value value="1810134"/>
      <value value="6193163"/>
      <value value="3833810"/>
      <value value="6857188"/>
      <value value="7378701"/>
      <value value="6814617"/>
      <value value="7823602"/>
      <value value="4075753"/>
      <value value="5235796"/>
      <value value="4341581"/>
      <value value="6824386"/>
      <value value="9981989"/>
      <value value="4037042"/>
      <value value="1232120"/>
      <value value="7489508"/>
      <value value="3490742"/>
      <value value="4979356"/>
      <value value="8979731"/>
      <value value="4185335"/>
      <value value="7699251"/>
      <value value="3960584"/>
      <value value="9767917"/>
      <value value="2715390"/>
      <value value="8264"/>
      <value value="1080207"/>
      <value value="5886694"/>
      <value value="6660855"/>
      <value value="3437296"/>
      <value value="5322469"/>
      <value value="770973"/>
      <value value="1786852"/>
      <value value="1479324"/>
      <value value="3021051"/>
      <value value="9993564"/>
      <value value="9497702"/>
      <value value="3253351"/>
      <value value="6097132"/>
      <value value="4502808"/>
      <value value="5435469"/>
      <value value="7209093"/>
      <value value="2224885"/>
      <value value="463640"/>
      <value value="2683548"/>
      <value value="349203"/>
      <value value="1970172"/>
      <value value="2272436"/>
      <value value="3915436"/>
      <value value="4936806"/>
      <value value="1664457"/>
      <value value="9212368"/>
      <value value="8304069"/>
      <value value="2369772"/>
      <value value="5640785"/>
      <value value="5774972"/>
      <value value="775079"/>
      <value value="5069785"/>
      <value value="1398146"/>
      <value value="7762916"/>
      <value value="6593245"/>
      <value value="1545700"/>
      <value value="411786"/>
      <value value="5397485"/>
      <value value="9419534"/>
      <value value="3154651"/>
      <value value="4509898"/>
      <value value="1893721"/>
      <value value="6033475"/>
      <value value="5357916"/>
      <value value="8745080"/>
      <value value="3199447"/>
      <value value="9320255"/>
      <value value="5827527"/>
      <value value="9513270"/>
      <value value="8047399"/>
      <value value="6670203"/>
      <value value="5103289"/>
      <value value="2086487"/>
      <value value="6177333"/>
      <value value="1974513"/>
      <value value="7770454"/>
      <value value="349272"/>
      <value value="322121"/>
      <value value="9962924"/>
      <value value="5932494"/>
      <value value="4233105"/>
      <value value="9994913"/>
      <value value="6616364"/>
      <value value="8997172"/>
      <value value="5064372"/>
      <value value="4893684"/>
      <value value="6378392"/>
      <value value="9527751"/>
      <value value="8423691"/>
      <value value="3825552"/>
      <value value="4478698"/>
      <value value="3864351"/>
      <value value="7366119"/>
      <value value="3647533"/>
      <value value="7785464"/>
      <value value="331994"/>
      <value value="3695149"/>
      <value value="4402937"/>
      <value value="8792802"/>
      <value value="8777171"/>
      <value value="9308815"/>
      <value value="1572833"/>
      <value value="9818083"/>
      <value value="6583358"/>
      <value value="4711467"/>
      <value value="8680933"/>
      <value value="9376501"/>
      <value value="5118637"/>
      <value value="6489232"/>
      <value value="7382354"/>
      <value value="5248041"/>
      <value value="208442"/>
      <value value="8042704"/>
      <value value="8879796"/>
      <value value="2803952"/>
      <value value="999025"/>
      <value value="4911200"/>
      <value value="5887119"/>
      <value value="4389201"/>
      <value value="1150651"/>
      <value value="6485042"/>
      <value value="5557984"/>
      <value value="9520112"/>
      <value value="7763616"/>
      <value value="3603879"/>
      <value value="7809605"/>
      <value value="6096316"/>
      <value value="8203940"/>
      <value value="5776466"/>
      <value value="1894927"/>
      <value value="252398"/>
      <value value="5783363"/>
      <value value="3920055"/>
      <value value="4459170"/>
      <value value="7575924"/>
      <value value="7953379"/>
      <value value="6157484"/>
      <value value="1973390"/>
      <value value="3744985"/>
      <value value="3541344"/>
      <value value="7054809"/>
      <value value="9440976"/>
      <value value="3224162"/>
      <value value="8299847"/>
      <value value="1368614"/>
      <value value="7212199"/>
      <value value="8407321"/>
      <value value="279871"/>
      <value value="8563477"/>
      <value value="4698248"/>
      <value value="2026357"/>
      <value value="3409181"/>
      <value value="8090644"/>
      <value value="9400320"/>
      <value value="1852605"/>
      <value value="6919225"/>
      <value value="5603562"/>
      <value value="1184638"/>
      <value value="4801039"/>
      <value value="622791"/>
      <value value="6119614"/>
      <value value="3602776"/>
      <value value="7019749"/>
      <value value="4057308"/>
      <value value="6525490"/>
      <value value="1665575"/>
      <value value="326737"/>
      <value value="3915114"/>
      <value value="4537342"/>
      <value value="8381694"/>
      <value value="9685400"/>
      <value value="777437"/>
      <value value="710537"/>
      <value value="4925997"/>
      <value value="8064528"/>
      <value value="8231831"/>
      <value value="3115076"/>
      <value value="6538550"/>
      <value value="8892783"/>
      <value value="4094018"/>
      <value value="6852248"/>
      <value value="7558749"/>
      <value value="6632753"/>
      <value value="2380645"/>
      <value value="576512"/>
      <value value="6911239"/>
      <value value="9930495"/>
      <value value="4989929"/>
      <value value="4215544"/>
      <value value="6147083"/>
      <value value="8789698"/>
      <value value="7581336"/>
      <value value="3959660"/>
      <value value="5714906"/>
      <value value="6805394"/>
      <value value="22811"/>
      <value value="634183"/>
      <value value="7541589"/>
      <value value="5681288"/>
      <value value="6818050"/>
      <value value="3275204"/>
      <value value="4137848"/>
      <value value="9820730"/>
      <value value="1149745"/>
      <value value="9105616"/>
      <value value="5817845"/>
      <value value="7397006"/>
      <value value="8641793"/>
      <value value="4586829"/>
      <value value="7036013"/>
      <value value="3572798"/>
      <value value="6524151"/>
      <value value="3493472"/>
      <value value="2857761"/>
      <value value="3992779"/>
      <value value="7243800"/>
      <value value="2062827"/>
      <value value="3889749"/>
      <value value="9508525"/>
      <value value="5167529"/>
      <value value="1052472"/>
      <value value="8448891"/>
      <value value="9955874"/>
      <value value="9834038"/>
      <value value="7964890"/>
      <value value="9021972"/>
      <value value="2487603"/>
      <value value="4031435"/>
      <value value="8247630"/>
      <value value="1929237"/>
      <value value="3643445"/>
      <value value="7218756"/>
      <value value="4997527"/>
      <value value="3425676"/>
      <value value="7987230"/>
      <value value="9702660"/>
      <value value="3533024"/>
      <value value="1860762"/>
      <value value="4318272"/>
      <value value="9592137"/>
      <value value="7792957"/>
      <value value="422986"/>
      <value value="1474666"/>
      <value value="1522403"/>
      <value value="4053107"/>
      <value value="3364294"/>
      <value value="1333879"/>
      <value value="5497647"/>
      <value value="2936709"/>
      <value value="9235769"/>
      <value value="1499015"/>
      <value value="5758446"/>
      <value value="9143192"/>
      <value value="3147582"/>
      <value value="621923"/>
      <value value="9949413"/>
      <value value="3462473"/>
      <value value="2538581"/>
      <value value="7904551"/>
      <value value="9713831"/>
      <value value="5323345"/>
      <value value="4269713"/>
      <value value="2806915"/>
      <value value="2398851"/>
      <value value="6915364"/>
      <value value="1812832"/>
      <value value="7182351"/>
      <value value="8534882"/>
      <value value="2254908"/>
      <value value="86291"/>
      <value value="6367603"/>
      <value value="8418404"/>
      <value value="1582148"/>
      <value value="4888978"/>
      <value value="9798712"/>
      <value value="1438866"/>
      <value value="1585674"/>
      <value value="6854599"/>
      <value value="1860592"/>
      <value value="6801414"/>
      <value value="7455698"/>
      <value value="8821694"/>
      <value value="780406"/>
      <value value="2472741"/>
      <value value="9855872"/>
      <value value="9509460"/>
      <value value="1867080"/>
      <value value="5689577"/>
      <value value="2011239"/>
      <value value="9956351"/>
      <value value="1098301"/>
      <value value="8409132"/>
      <value value="6679663"/>
      <value value="2046167"/>
      <value value="2480708"/>
      <value value="3967493"/>
      <value value="2713372"/>
      <value value="9690715"/>
      <value value="3220565"/>
      <value value="7182474"/>
      <value value="8825973"/>
      <value value="9256086"/>
      <value value="6923927"/>
      <value value="4310991"/>
      <value value="4614555"/>
      <value value="5363304"/>
      <value value="5018074"/>
      <value value="745177"/>
      <value value="4135442"/>
      <value value="4145589"/>
      <value value="4566618"/>
      <value value="4366003"/>
      <value value="4235000"/>
      <value value="7897144"/>
      <value value="1142560"/>
      <value value="4825625"/>
      <value value="1059047"/>
      <value value="4839605"/>
      <value value="1050865"/>
      <value value="6389003"/>
      <value value="7290273"/>
      <value value="9338067"/>
      <value value="9015185"/>
      <value value="8338052"/>
      <value value="148761"/>
      <value value="2840952"/>
      <value value="6665735"/>
      <value value="4916956"/>
      <value value="1260421"/>
      <value value="8392731"/>
      <value value="8798044"/>
      <value value="8888025"/>
      <value value="1547066"/>
      <value value="392620"/>
      <value value="1867994"/>
      <value value="1784416"/>
      <value value="7481542"/>
      <value value="6019840"/>
      <value value="1490338"/>
      <value value="3631851"/>
      <value value="8812291"/>
      <value value="216182"/>
      <value value="8348835"/>
      <value value="2870095"/>
      <value value="8414751"/>
      <value value="3090797"/>
      <value value="101205"/>
      <value value="1685060"/>
      <value value="3008746"/>
      <value value="2156767"/>
      <value value="777480"/>
      <value value="1934285"/>
      <value value="8984892"/>
      <value value="1516420"/>
      <value value="1853451"/>
      <value value="474119"/>
      <value value="4971947"/>
      <value value="1614360"/>
      <value value="5788011"/>
      <value value="8615155"/>
      <value value="8672623"/>
      <value value="9363059"/>
      <value value="8826437"/>
      <value value="2928027"/>
      <value value="7807468"/>
      <value value="3329316"/>
      <value value="3999592"/>
      <value value="5756036"/>
      <value value="8962724"/>
      <value value="8913709"/>
      <value value="4429125"/>
      <value value="3244537"/>
      <value value="5928828"/>
      <value value="6444884"/>
      <value value="847433"/>
      <value value="99192"/>
      <value value="3689235"/>
      <value value="7264672"/>
      <value value="6298424"/>
      <value value="5294610"/>
      <value value="667662"/>
      <value value="4296225"/>
      <value value="2797728"/>
      <value value="8890343"/>
      <value value="2517797"/>
      <value value="3759779"/>
      <value value="3530702"/>
      <value value="1754878"/>
      <value value="6346930"/>
      <value value="5430658"/>
      <value value="4207896"/>
      <value value="7840291"/>
      <value value="5025973"/>
      <value value="879036"/>
      <value value="1129819"/>
      <value value="8593667"/>
      <value value="6867017"/>
      <value value="2124829"/>
      <value value="8639952"/>
      <value value="981637"/>
      <value value="9215794"/>
      <value value="2820232"/>
      <value value="9097378"/>
      <value value="3658173"/>
      <value value="6495901"/>
      <value value="413748"/>
      <value value="7832585"/>
      <value value="770806"/>
      <value value="3282948"/>
      <value value="3210860"/>
      <value value="524234"/>
      <value value="9687746"/>
      <value value="5876076"/>
      <value value="7602092"/>
      <value value="377908"/>
      <value value="898401"/>
      <value value="6803236"/>
      <value value="4210735"/>
      <value value="5396642"/>
      <value value="8122813"/>
      <value value="4351050"/>
      <value value="1688791"/>
      <value value="2650516"/>
      <value value="136541"/>
      <value value="2584900"/>
      <value value="7195248"/>
      <value value="7615792"/>
      <value value="4445008"/>
      <value value="5820613"/>
      <value value="8549197"/>
      <value value="4819153"/>
      <value value="9588256"/>
      <value value="7840093"/>
      <value value="3502366"/>
      <value value="2131627"/>
      <value value="1879747"/>
      <value value="7911700"/>
      <value value="9914640"/>
      <value value="9779732"/>
      <value value="7779433"/>
      <value value="4774948"/>
      <value value="1617916"/>
      <value value="6184526"/>
      <value value="5794466"/>
      <value value="2010846"/>
      <value value="9549207"/>
      <value value="5716123"/>
      <value value="2116971"/>
      <value value="5055581"/>
      <value value="443889"/>
      <value value="504465"/>
      <value value="6951292"/>
      <value value="5572101"/>
      <value value="4603604"/>
      <value value="5896214"/>
      <value value="7275186"/>
      <value value="2859770"/>
      <value value="8712227"/>
      <value value="6850812"/>
      <value value="1524278"/>
      <value value="7761644"/>
      <value value="8731728"/>
      <value value="9968656"/>
      <value value="3794558"/>
      <value value="6468982"/>
      <value value="8921595"/>
      <value value="9521103"/>
      <value value="2442117"/>
      <value value="2488696"/>
      <value value="2129865"/>
      <value value="7396034"/>
      <value value="8986202"/>
      <value value="9627588"/>
      <value value="9995566"/>
      <value value="5451858"/>
      <value value="966528"/>
      <value value="5876364"/>
      <value value="4990903"/>
      <value value="5376422"/>
      <value value="6083859"/>
      <value value="2240823"/>
      <value value="3369786"/>
      <value value="4136240"/>
      <value value="7790830"/>
      <value value="4360141"/>
      <value value="8148254"/>
      <value value="8503805"/>
      <value value="6977238"/>
      <value value="3774409"/>
      <value value="5779801"/>
      <value value="4663114"/>
      <value value="8604341"/>
      <value value="5266586"/>
      <value value="9202366"/>
      <value value="7961652"/>
      <value value="1130004"/>
      <value value="2521749"/>
      <value value="5011006"/>
      <value value="9983978"/>
      <value value="446585"/>
      <value value="6638285"/>
      <value value="4587114"/>
      <value value="3467915"/>
      <value value="9360802"/>
      <value value="9869202"/>
      <value value="1928732"/>
      <value value="1537321"/>
      <value value="5760580"/>
      <value value="4810061"/>
      <value value="1497984"/>
      <value value="376975"/>
      <value value="4662136"/>
      <value value="259408"/>
      <value value="5631627"/>
      <value value="3443678"/>
      <value value="2222276"/>
      <value value="9871922"/>
      <value value="467518"/>
      <value value="9201325"/>
      <value value="5710742"/>
      <value value="3860423"/>
      <value value="163897"/>
      <value value="7960467"/>
      <value value="9817698"/>
      <value value="2492725"/>
      <value value="6713697"/>
      <value value="5126314"/>
      <value value="8814250"/>
      <value value="8859216"/>
      <value value="923121"/>
      <value value="5660489"/>
      <value value="2017974"/>
      <value value="2939043"/>
      <value value="349247"/>
      <value value="1385836"/>
      <value value="964436"/>
      <value value="4984129"/>
      <value value="8688073"/>
      <value value="3429476"/>
      <value value="2653144"/>
      <value value="8221012"/>
      <value value="2224809"/>
      <value value="8391110"/>
      <value value="9424072"/>
      <value value="6920449"/>
      <value value="9151334"/>
      <value value="6976433"/>
      <value value="8841632"/>
      <value value="8502813"/>
      <value value="226016"/>
      <value value="172077"/>
      <value value="5308295"/>
      <value value="7288220"/>
      <value value="8363559"/>
      <value value="2500774"/>
      <value value="5395695"/>
      <value value="9580546"/>
      <value value="516111"/>
      <value value="7704408"/>
      <value value="9131746"/>
      <value value="2402278"/>
      <value value="9023126"/>
      <value value="7555705"/>
      <value value="8678522"/>
      <value value="305324"/>
      <value value="1798349"/>
      <value value="301738"/>
      <value value="3494856"/>
      <value value="7281118"/>
      <value value="8474192"/>
      <value value="289686"/>
      <value value="7858334"/>
      <value value="4698469"/>
      <value value="7472665"/>
      <value value="831345"/>
      <value value="782089"/>
      <value value="8787718"/>
      <value value="9359559"/>
      <value value="9972433"/>
      <value value="2903274"/>
      <value value="7876726"/>
      <value value="7047891"/>
      <value value="6800261"/>
      <value value="2471649"/>
      <value value="4659995"/>
      <value value="5605875"/>
      <value value="4623632"/>
      <value value="2822512"/>
      <value value="1164876"/>
      <value value="1016157"/>
      <value value="8980193"/>
      <value value="4060201"/>
      <value value="1851616"/>
      <value value="8127806"/>
      <value value="3665969"/>
      <value value="2230951"/>
      <value value="3593895"/>
      <value value="8390945"/>
      <value value="5500191"/>
      <value value="7033032"/>
      <value value="6946388"/>
      <value value="150478"/>
      <value value="100278"/>
      <value value="8482893"/>
      <value value="8435952"/>
      <value value="6271788"/>
      <value value="5013144"/>
      <value value="7019313"/>
      <value value="7157560"/>
      <value value="2222656"/>
      <value value="6100709"/>
      <value value="6410338"/>
      <value value="6916593"/>
      <value value="4142739"/>
      <value value="3140110"/>
      <value value="6492839"/>
      <value value="3425939"/>
      <value value="7268368"/>
      <value value="1767963"/>
      <value value="2440616"/>
      <value value="3960582"/>
      <value value="431830"/>
      <value value="6957617"/>
      <value value="6553442"/>
      <value value="4249860"/>
      <value value="198153"/>
      <value value="552695"/>
      <value value="6446792"/>
      <value value="330831"/>
      <value value="9108004"/>
      <value value="8707192"/>
      <value value="3562150"/>
      <value value="8435144"/>
      <value value="4942877"/>
      <value value="6519176"/>
      <value value="7666137"/>
      <value value="5505681"/>
      <value value="6412074"/>
      <value value="3126401"/>
      <value value="1282222"/>
      <value value="7002539"/>
      <value value="6390565"/>
      <value value="6802873"/>
      <value value="2306226"/>
      <value value="643270"/>
      <value value="6993003"/>
      <value value="2685608"/>
      <value value="6861601"/>
      <value value="8396898"/>
      <value value="1327384"/>
      <value value="9111549"/>
      <value value="9356322"/>
      <value value="8858027"/>
      <value value="1070067"/>
      <value value="5368650"/>
      <value value="9012108"/>
      <value value="9932523"/>
      <value value="4272554"/>
      <value value="7034237"/>
      <value value="387876"/>
      <value value="3315753"/>
      <value value="7174875"/>
      <value value="8923180"/>
      <value value="9279010"/>
      <value value="1406181"/>
      <value value="7000034"/>
      <value value="3983127"/>
      <value value="9224944"/>
      <value value="4080003"/>
      <value value="6328493"/>
      <value value="5810139"/>
      <value value="7304367"/>
      <value value="3936591"/>
      <value value="6755627"/>
      <value value="9859811"/>
      <value value="6041858"/>
      <value value="9451889"/>
      <value value="8749364"/>
      <value value="4436148"/>
      <value value="1287186"/>
      <value value="211787"/>
      <value value="9569813"/>
      <value value="633138"/>
      <value value="1926601"/>
      <value value="7601567"/>
      <value value="5470665"/>
      <value value="9011661"/>
      <value value="1829593"/>
      <value value="858555"/>
      <value value="5147413"/>
      <value value="7992629"/>
      <value value="6654782"/>
      <value value="3381695"/>
      <value value="4158208"/>
      <value value="8051123"/>
      <value value="9742618"/>
      <value value="5275377"/>
      <value value="3424978"/>
      <value value="9383501"/>
      <value value="7370888"/>
      <value value="2874312"/>
      <value value="9546130"/>
      <value value="2211896"/>
      <value value="6880615"/>
      <value value="2429153"/>
      <value value="9982120"/>
      <value value="2446902"/>
      <value value="2999496"/>
      <value value="6627273"/>
      <value value="3877150"/>
      <value value="9911376"/>
      <value value="6402406"/>
      <value value="4779261"/>
      <value value="7622529"/>
      <value value="8775177"/>
      <value value="7570386"/>
      <value value="6219443"/>
      <value value="7933789"/>
      <value value="6237150"/>
      <value value="6351756"/>
      <value value="4852775"/>
      <value value="9602107"/>
      <value value="528941"/>
      <value value="2215083"/>
      <value value="4767613"/>
      <value value="713816"/>
      <value value="9821500"/>
      <value value="7711032"/>
      <value value="241233"/>
      <value value="2193679"/>
      <value value="7794220"/>
      <value value="8201755"/>
      <value value="678239"/>
      <value value="5331166"/>
      <value value="295971"/>
      <value value="1770574"/>
      <value value="8141461"/>
      <value value="3683686"/>
      <value value="7652721"/>
      <value value="7214936"/>
      <value value="4791036"/>
      <value value="7068246"/>
      <value value="3452101"/>
      <value value="463458"/>
      <value value="9157967"/>
      <value value="2712928"/>
      <value value="5503583"/>
      <value value="5970759"/>
      <value value="3559537"/>
      <value value="3670404"/>
      <value value="6823198"/>
      <value value="8505514"/>
      <value value="1152152"/>
      <value value="5957484"/>
      <value value="111706"/>
      <value value="78309"/>
      <value value="3899704"/>
      <value value="7393194"/>
      <value value="3565559"/>
      <value value="327091"/>
      <value value="1910784"/>
      <value value="5437537"/>
      <value value="4396623"/>
      <value value="9915257"/>
      <value value="319734"/>
      <value value="1792057"/>
      <value value="6203959"/>
      <value value="5113760"/>
      <value value="6335210"/>
      <value value="6315031"/>
      <value value="5748030"/>
      <value value="4144015"/>
      <value value="2030647"/>
      <value value="7382870"/>
      <value value="8669727"/>
      <value value="824936"/>
      <value value="8787653"/>
      <value value="3343086"/>
      <value value="3201045"/>
      <value value="3753282"/>
      <value value="2037872"/>
      <value value="9096666"/>
      <value value="2058801"/>
      <value value="3819638"/>
      <value value="6411779"/>
      <value value="3324097"/>
      <value value="5597763"/>
      <value value="7278459"/>
      <value value="9942876"/>
      <value value="4183763"/>
      <value value="8203502"/>
      <value value="5136543"/>
      <value value="1790210"/>
      <value value="4241200"/>
      <value value="242539"/>
      <value value="6259386"/>
      <value value="8816084"/>
      <value value="6772332"/>
      <value value="8571183"/>
      <value value="354656"/>
      <value value="8548697"/>
      <value value="7282036"/>
      <value value="3276795"/>
      <value value="6521786"/>
      <value value="3318536"/>
      <value value="5335385"/>
      <value value="5938055"/>
      <value value="9190681"/>
      <value value="8447629"/>
      <value value="73472"/>
      <value value="1195493"/>
      <value value="900574"/>
      <value value="444845"/>
      <value value="5961544"/>
      <value value="5650298"/>
      <value value="7889724"/>
      <value value="1326804"/>
      <value value="2297847"/>
      <value value="8770335"/>
      <value value="6403128"/>
      <value value="4219550"/>
      <value value="1593803"/>
      <value value="110125"/>
      <value value="1779641"/>
      <value value="5827279"/>
      <value value="1845299"/>
      <value value="256947"/>
      <value value="7171414"/>
      <value value="287304"/>
      <value value="7350753"/>
      <value value="1903795"/>
      <value value="1243882"/>
      <value value="383449"/>
      <value value="7482271"/>
      <value value="2691542"/>
      <value value="7767803"/>
      <value value="3514274"/>
      <value value="3693964"/>
      <value value="8584702"/>
      <value value="60159"/>
      <value value="8321477"/>
      <value value="3902166"/>
      <value value="652769"/>
      <value value="238673"/>
      <value value="5871445"/>
      <value value="2128099"/>
      <value value="8703610"/>
      <value value="5166546"/>
      <value value="3311251"/>
      <value value="1566301"/>
      <value value="697480"/>
      <value value="8258948"/>
      <value value="1834207"/>
      <value value="8012942"/>
      <value value="29767"/>
      <value value="3238106"/>
      <value value="4854680"/>
      <value value="2382762"/>
      <value value="6049308"/>
      <value value="2137195"/>
      <value value="9947199"/>
      <value value="3365460"/>
      <value value="646131"/>
      <value value="3474327"/>
      <value value="7161235"/>
      <value value="9186213"/>
      <value value="7395224"/>
      <value value="7157421"/>
      <value value="9558837"/>
      <value value="5071079"/>
      <value value="8389837"/>
      <value value="7617727"/>
      <value value="5608020"/>
      <value value="2563082"/>
      <value value="4690162"/>
      <value value="6766795"/>
      <value value="9426223"/>
      <value value="6448429"/>
      <value value="8193225"/>
      <value value="8689549"/>
      <value value="8548185"/>
      <value value="2361305"/>
      <value value="9430647"/>
      <value value="463182"/>
      <value value="4220221"/>
      <value value="6211500"/>
      <value value="8966910"/>
      <value value="5390831"/>
      <value value="9765768"/>
      <value value="9897431"/>
      <value value="8811098"/>
      <value value="1506530"/>
      <value value="4364855"/>
      <value value="1719437"/>
      <value value="1002003"/>
      <value value="743750"/>
      <value value="2662646"/>
      <value value="8396953"/>
      <value value="8063896"/>
      <value value="9849223"/>
      <value value="9675726"/>
      <value value="4929940"/>
      <value value="7596540"/>
      <value value="6744640"/>
      <value value="9916683"/>
      <value value="1936095"/>
      <value value="8578671"/>
      <value value="9327339"/>
      <value value="2915402"/>
      <value value="9503799"/>
      <value value="6382052"/>
      <value value="795104"/>
      <value value="8395611"/>
      <value value="6183329"/>
      <value value="98955"/>
      <value value="8972335"/>
      <value value="2495330"/>
      <value value="5917613"/>
      <value value="3664299"/>
      <value value="6912931"/>
      <value value="6475010"/>
      <value value="4704065"/>
      <value value="6499211"/>
      <value value="4737849"/>
      <value value="4865330"/>
      <value value="8623683"/>
      <value value="7216043"/>
      <value value="2562142"/>
      <value value="806159"/>
      <value value="7913086"/>
      <value value="7452208"/>
      <value value="900810"/>
      <value value="9815827"/>
      <value value="9508205"/>
      <value value="3374744"/>
      <value value="9590477"/>
      <value value="9874745"/>
      <value value="6188696"/>
      <value value="6517654"/>
      <value value="6799347"/>
      <value value="8427402"/>
      <value value="4177858"/>
      <value value="7657520"/>
      <value value="8919594"/>
      <value value="911537"/>
      <value value="7886312"/>
      <value value="586216"/>
      <value value="322829"/>
      <value value="535916"/>
      <value value="9924817"/>
      <value value="9011254"/>
      <value value="5380692"/>
      <value value="8231782"/>
      <value value="3302889"/>
      <value value="7256720"/>
      <value value="4336179"/>
      <value value="5753589"/>
      <value value="4161440"/>
      <value value="8797377"/>
      <value value="6334703"/>
      <value value="9553774"/>
      <value value="669499"/>
      <value value="4793194"/>
      <value value="2275246"/>
      <value value="5198368"/>
      <value value="1542564"/>
      <value value="4163353"/>
      <value value="5924352"/>
      <value value="1332112"/>
      <value value="4467127"/>
      <value value="1445646"/>
      <value value="1145700"/>
      <value value="9344121"/>
      <value value="2773813"/>
      <value value="1914444"/>
      <value value="3113781"/>
      <value value="5642849"/>
      <value value="2686809"/>
      <value value="4517007"/>
      <value value="1798793"/>
      <value value="8916465"/>
      <value value="6509025"/>
      <value value="2524178"/>
      <value value="3217522"/>
      <value value="9051755"/>
      <value value="4740349"/>
      <value value="9277183"/>
      <value value="6900939"/>
      <value value="6553900"/>
      <value value="2452042"/>
      <value value="2345027"/>
      <value value="6832512"/>
      <value value="6575142"/>
      <value value="8362513"/>
      <value value="6604922"/>
      <value value="7267110"/>
      <value value="7534126"/>
      <value value="1627986"/>
      <value value="1555479"/>
      <value value="8393012"/>
      <value value="3604663"/>
      <value value="6571951"/>
      <value value="7224099"/>
      <value value="4591993"/>
      <value value="4161666"/>
      <value value="4140867"/>
      <value value="7236868"/>
      <value value="2762580"/>
      <value value="4815711"/>
      <value value="7382100"/>
      <value value="772523"/>
      <value value="1245770"/>
      <value value="2912247"/>
      <value value="3173249"/>
      <value value="8454406"/>
      <value value="2622636"/>
      <value value="3329993"/>
      <value value="9398981"/>
      <value value="8394099"/>
      <value value="4729832"/>
      <value value="6975858"/>
      <value value="6821046"/>
      <value value="5574075"/>
      <value value="5063680"/>
      <value value="2994437"/>
      <value value="8751036"/>
      <value value="1706618"/>
      <value value="6329674"/>
      <value value="2018954"/>
      <value value="2330509"/>
      <value value="1139233"/>
      <value value="5732650"/>
      <value value="3588492"/>
      <value value="4932410"/>
      <value value="8482586"/>
      <value value="4023981"/>
      <value value="4934970"/>
      <value value="328044"/>
      <value value="4080091"/>
      <value value="9953216"/>
      <value value="277407"/>
      <value value="1017736"/>
      <value value="212025"/>
      <value value="567326"/>
      <value value="8641983"/>
      <value value="5330990"/>
      <value value="1633654"/>
      <value value="8252535"/>
      <value value="3889845"/>
      <value value="5331146"/>
      <value value="5353898"/>
      <value value="1058691"/>
      <value value="1702139"/>
      <value value="6536046"/>
      <value value="3998722"/>
      <value value="4796776"/>
      <value value="2258971"/>
      <value value="4380215"/>
      <value value="4926594"/>
      <value value="1982231"/>
      <value value="6603583"/>
      <value value="5523207"/>
      <value value="5296924"/>
      <value value="8403791"/>
      <value value="3356423"/>
      <value value="8036038"/>
      <value value="8371223"/>
      <value value="9614066"/>
      <value value="9874728"/>
      <value value="7505291"/>
      <value value="2527712"/>
      <value value="6574282"/>
      <value value="93653"/>
      <value value="1877638"/>
      <value value="2744769"/>
      <value value="8497292"/>
      <value value="2820248"/>
      <value value="9121030"/>
      <value value="2080291"/>
      <value value="7482228"/>
      <value value="2348788"/>
      <value value="5934266"/>
      <value value="4991025"/>
      <value value="3301155"/>
      <value value="5450572"/>
      <value value="2555865"/>
      <value value="7347477"/>
      <value value="3338107"/>
      <value value="5093858"/>
      <value value="5652645"/>
      <value value="9009213"/>
      <value value="6227313"/>
      <value value="3718062"/>
      <value value="9495372"/>
      <value value="958686"/>
      <value value="9227154"/>
      <value value="1538055"/>
      <value value="7233546"/>
      <value value="5011264"/>
      <value value="3172299"/>
      <value value="5817549"/>
      <value value="7615866"/>
      <value value="3277192"/>
      <value value="5546713"/>
      <value value="3721092"/>
      <value value="3414827"/>
      <value value="4120943"/>
      <value value="4191221"/>
      <value value="7080342"/>
      <value value="3546518"/>
      <value value="5587704"/>
      <value value="5155394"/>
      <value value="6642963"/>
      <value value="638950"/>
      <value value="8802049"/>
      <value value="3300460"/>
      <value value="2579949"/>
      <value value="4963792"/>
      <value value="5880268"/>
      <value value="2068644"/>
      <value value="1003181"/>
      <value value="9635772"/>
      <value value="357061"/>
      <value value="7558853"/>
      <value value="3309569"/>
      <value value="1243482"/>
      <value value="4502795"/>
      <value value="898884"/>
      <value value="5245851"/>
      <value value="9113826"/>
      <value value="3912652"/>
      <value value="6091336"/>
      <value value="9777851"/>
      <value value="8225575"/>
      <value value="5420534"/>
      <value value="323509"/>
      <value value="4096984"/>
      <value value="5360904"/>
      <value value="3365092"/>
      <value value="6729949"/>
      <value value="1194796"/>
      <value value="7506985"/>
      <value value="5220283"/>
      <value value="2593230"/>
      <value value="1300909"/>
      <value value="5137534"/>
      <value value="3914219"/>
      <value value="1473519"/>
      <value value="3995458"/>
      <value value="8576928"/>
      <value value="203815"/>
      <value value="3183903"/>
      <value value="8406303"/>
      <value value="4997366"/>
      <value value="4137940"/>
      <value value="5574080"/>
      <value value="2910764"/>
      <value value="1681804"/>
      <value value="6736173"/>
      <value value="1610952"/>
      <value value="2139270"/>
      <value value="4381863"/>
      <value value="810137"/>
      <value value="1842858"/>
      <value value="9148602"/>
      <value value="4641591"/>
      <value value="9269970"/>
      <value value="7460351"/>
      <value value="7888623"/>
      <value value="9771057"/>
      <value value="3364510"/>
      <value value="3956787"/>
      <value value="1568098"/>
      <value value="6208399"/>
      <value value="2081663"/>
      <value value="8719902"/>
      <value value="7933449"/>
      <value value="3869290"/>
      <value value="9404667"/>
      <value value="2897608"/>
      <value value="3503822"/>
      <value value="391938"/>
      <value value="511060"/>
      <value value="8484941"/>
      <value value="1484029"/>
      <value value="280577"/>
      <value value="6963871"/>
      <value value="168960"/>
      <value value="6928752"/>
      <value value="4946975"/>
      <value value="5300620"/>
      <value value="783138"/>
      <value value="5367819"/>
      <value value="8497144"/>
      <value value="2350264"/>
      <value value="9258196"/>
      <value value="3791268"/>
      <value value="2083129"/>
      <value value="1020384"/>
      <value value="7750294"/>
      <value value="4990955"/>
      <value value="7000694"/>
      <value value="8567121"/>
      <value value="3725697"/>
      <value value="4661242"/>
      <value value="7069191"/>
      <value value="913005"/>
      <value value="1936963"/>
      <value value="1202317"/>
      <value value="6963461"/>
      <value value="5636107"/>
      <value value="7864770"/>
      <value value="1364940"/>
      <value value="2584953"/>
      <value value="1879652"/>
      <value value="2810276"/>
      <value value="3665833"/>
      <value value="4304683"/>
      <value value="8374434"/>
      <value value="8544005"/>
      <value value="3316002"/>
      <value value="4805538"/>
      <value value="3850495"/>
      <value value="3948733"/>
      <value value="9585453"/>
      <value value="6498294"/>
      <value value="745441"/>
      <value value="8270387"/>
      <value value="1388832"/>
      <value value="737171"/>
      <value value="8437272"/>
      <value value="9722986"/>
      <value value="5685389"/>
      <value value="6691692"/>
      <value value="9539390"/>
      <value value="6968942"/>
      <value value="1982019"/>
      <value value="3509687"/>
      <value value="7454869"/>
      <value value="5245496"/>
      <value value="6553883"/>
      <value value="6474800"/>
      <value value="120772"/>
      <value value="6757581"/>
      <value value="5444035"/>
      <value value="354171"/>
      <value value="7115752"/>
      <value value="8948349"/>
      <value value="3805940"/>
      <value value="559157"/>
      <value value="1277082"/>
      <value value="7552695"/>
      <value value="8113085"/>
      <value value="2149828"/>
      <value value="2741823"/>
      <value value="110489"/>
      <value value="2676044"/>
      <value value="937682"/>
      <value value="1042360"/>
      <value value="9502641"/>
      <value value="6983011"/>
      <value value="3139934"/>
      <value value="7407279"/>
      <value value="3440881"/>
      <value value="4705575"/>
      <value value="625587"/>
      <value value="339923"/>
      <value value="5132091"/>
      <value value="7080179"/>
      <value value="1912399"/>
      <value value="7181695"/>
      <value value="5968600"/>
      <value value="5997222"/>
      <value value="2018393"/>
      <value value="4862855"/>
      <value value="7025895"/>
      <value value="2150809"/>
      <value value="859595"/>
      <value value="8992733"/>
      <value value="7397000"/>
      <value value="2428513"/>
      <value value="6607097"/>
      <value value="7548275"/>
      <value value="8442758"/>
      <value value="1147888"/>
      <value value="1832663"/>
      <value value="1803916"/>
      <value value="4063736"/>
      <value value="5140550"/>
      <value value="9611059"/>
      <value value="875527"/>
      <value value="1625265"/>
      <value value="7838942"/>
      <value value="8261168"/>
      <value value="2759449"/>
      <value value="5771868"/>
      <value value="8035073"/>
      <value value="2738979"/>
      <value value="4521946"/>
      <value value="8495472"/>
      <value value="9228105"/>
      <value value="786346"/>
      <value value="2212873"/>
      <value value="4058832"/>
      <value value="1419616"/>
      <value value="4016686"/>
      <value value="3673139"/>
      <value value="3593572"/>
      <value value="9382611"/>
      <value value="2096894"/>
      <value value="9393863"/>
      <value value="8166876"/>
      <value value="4929272"/>
      <value value="4873859"/>
      <value value="1853053"/>
      <value value="9903814"/>
      <value value="4698802"/>
      <value value="4445299"/>
      <value value="9262332"/>
      <value value="5557732"/>
      <value value="9072776"/>
      <value value="8731048"/>
      <value value="9364917"/>
      <value value="1498520"/>
      <value value="124761"/>
      <value value="9680527"/>
      <value value="6184288"/>
      <value value="4827536"/>
      <value value="3585110"/>
      <value value="2805910"/>
      <value value="4285811"/>
      <value value="633365"/>
      <value value="7103801"/>
      <value value="2711748"/>
      <value value="7136179"/>
      <value value="9269924"/>
      <value value="2064285"/>
      <value value="2681259"/>
      <value value="4337011"/>
      <value value="1088899"/>
      <value value="2647601"/>
      <value value="1544978"/>
      <value value="1871854"/>
      <value value="7594389"/>
      <value value="5626530"/>
      <value value="9320292"/>
      <value value="6974851"/>
      <value value="7565087"/>
      <value value="9759955"/>
      <value value="7890743"/>
      <value value="2892860"/>
      <value value="9418876"/>
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
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="76"/>
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
      <value value="0.25"/>
      <value value="0.27"/>
      <value value="0.29"/>
      <value value="0.31"/>
      <value value="0.33"/>
      <value value="0.35"/>
      <value value="0.37"/>
      <value value="0.39"/>
      <value value="0.41"/>
      <value value="0.43"/>
      <value value="0.45"/>
      <value value="0.47"/>
      <value value="0.49"/>
      <value value="0.51"/>
      <value value="0.53"/>
      <value value="0.55"/>
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
      <value value="40"/>
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
      <value value="20"/>
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
      <value value="2500000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
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
      <value value="8.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="find_2.5" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>average_R</metric>
    <metric>global_transmissability</metric>
    <metric>days</metric>
    <metric>totalEndCount</metric>
    <metric>scalephase</metric>
    <metric>cumulativeInfected</metric>
    <metric>infectionsToday</metric>
    <metric>slopeAverage</metric>
    <enumeratedValueSet variable="rand_seed">
      <value value="9678787"/>
      <value value="9676644"/>
      <value value="6295136"/>
      <value value="9709519"/>
      <value value="1283760"/>
      <value value="2700663"/>
      <value value="9430240"/>
      <value value="5184395"/>
      <value value="1718452"/>
      <value value="3761002"/>
      <value value="4044220"/>
      <value value="4745269"/>
      <value value="2122841"/>
      <value value="5050363"/>
      <value value="5267812"/>
      <value value="8004820"/>
      <value value="3734113"/>
      <value value="2057604"/>
      <value value="3583564"/>
      <value value="93352"/>
      <value value="6335523"/>
      <value value="2326451"/>
      <value value="9772107"/>
      <value value="2751822"/>
      <value value="9531991"/>
      <value value="6267269"/>
      <value value="5493545"/>
      <value value="8398160"/>
      <value value="6857654"/>
      <value value="1142111"/>
      <value value="2922723"/>
      <value value="3748058"/>
      <value value="3102542"/>
      <value value="5608439"/>
      <value value="4786596"/>
      <value value="7439743"/>
      <value value="1581532"/>
      <value value="3022971"/>
      <value value="3897131"/>
      <value value="5304307"/>
      <value value="2258847"/>
      <value value="9893698"/>
      <value value="9172206"/>
      <value value="4627604"/>
      <value value="9335121"/>
      <value value="7630641"/>
      <value value="4973705"/>
      <value value="6504610"/>
      <value value="6725896"/>
      <value value="8002030"/>
      <value value="9931178"/>
      <value value="2961648"/>
      <value value="6836632"/>
      <value value="5278647"/>
      <value value="6612254"/>
      <value value="808855"/>
      <value value="6808283"/>
      <value value="2725355"/>
      <value value="3106991"/>
      <value value="412288"/>
      <value value="3634779"/>
      <value value="3609788"/>
      <value value="4237332"/>
      <value value="2323364"/>
      <value value="9438840"/>
      <value value="7671890"/>
      <value value="3227604"/>
      <value value="9238399"/>
      <value value="2125188"/>
      <value value="5756532"/>
      <value value="8265876"/>
      <value value="8639621"/>
      <value value="62760"/>
      <value value="2134938"/>
      <value value="4019785"/>
      <value value="5741457"/>
      <value value="6947148"/>
      <value value="9321058"/>
      <value value="4051021"/>
      <value value="7066204"/>
      <value value="7005386"/>
      <value value="7755598"/>
      <value value="4727672"/>
      <value value="1838985"/>
      <value value="6620055"/>
      <value value="3052863"/>
      <value value="6484492"/>
      <value value="3948474"/>
      <value value="1357701"/>
      <value value="8899420"/>
      <value value="6841481"/>
      <value value="2780726"/>
      <value value="4177805"/>
      <value value="4781440"/>
      <value value="8324125"/>
      <value value="7661063"/>
      <value value="1640268"/>
      <value value="2052746"/>
      <value value="9189095"/>
      <value value="2410235"/>
      <value value="5963600"/>
      <value value="4633158"/>
      <value value="5057373"/>
      <value value="5094349"/>
      <value value="1685886"/>
      <value value="8945439"/>
      <value value="4181172"/>
      <value value="9447935"/>
      <value value="6213798"/>
      <value value="942303"/>
      <value value="3314314"/>
      <value value="7760553"/>
      <value value="1039313"/>
      <value value="5753467"/>
      <value value="6740212"/>
      <value value="408722"/>
      <value value="2510956"/>
      <value value="8307449"/>
      <value value="6227318"/>
      <value value="1194313"/>
      <value value="1041541"/>
      <value value="3269597"/>
      <value value="8553364"/>
      <value value="1131101"/>
      <value value="7233026"/>
      <value value="5704027"/>
      <value value="5844836"/>
      <value value="7042750"/>
      <value value="3309225"/>
      <value value="5896615"/>
      <value value="3807887"/>
      <value value="2889504"/>
      <value value="1661658"/>
      <value value="2971675"/>
      <value value="2453414"/>
      <value value="8849175"/>
      <value value="4045351"/>
      <value value="7672243"/>
      <value value="1191404"/>
      <value value="771124"/>
      <value value="7724216"/>
      <value value="5988584"/>
      <value value="3076125"/>
      <value value="4857086"/>
      <value value="1059679"/>
      <value value="99024"/>
      <value value="8446280"/>
      <value value="7696835"/>
      <value value="3399931"/>
      <value value="3782908"/>
      <value value="4588961"/>
      <value value="3715678"/>
      <value value="3197412"/>
      <value value="4770267"/>
      <value value="8818929"/>
      <value value="858592"/>
      <value value="3813596"/>
      <value value="702842"/>
      <value value="8837764"/>
      <value value="7311939"/>
      <value value="8990591"/>
      <value value="7480150"/>
      <value value="1533132"/>
      <value value="986933"/>
      <value value="7866570"/>
      <value value="1926293"/>
      <value value="6681180"/>
      <value value="1012782"/>
      <value value="7782034"/>
      <value value="8513904"/>
      <value value="4938300"/>
      <value value="7585318"/>
      <value value="8114306"/>
      <value value="9517128"/>
      <value value="5152116"/>
      <value value="7075996"/>
      <value value="8952144"/>
      <value value="801733"/>
      <value value="9303373"/>
      <value value="1209603"/>
      <value value="2022321"/>
      <value value="1627349"/>
      <value value="7006817"/>
      <value value="7062053"/>
      <value value="8552684"/>
      <value value="7173206"/>
      <value value="9215824"/>
      <value value="989539"/>
      <value value="5719124"/>
      <value value="1885367"/>
      <value value="4262333"/>
      <value value="302648"/>
      <value value="8396866"/>
      <value value="1793591"/>
      <value value="6185978"/>
      <value value="1950752"/>
      <value value="4151105"/>
      <value value="8595068"/>
      <value value="1034915"/>
      <value value="6018415"/>
      <value value="1369433"/>
      <value value="7325598"/>
      <value value="2481898"/>
      <value value="5516971"/>
      <value value="6432773"/>
      <value value="3648679"/>
      <value value="3949225"/>
      <value value="7845302"/>
      <value value="1718047"/>
      <value value="7011128"/>
      <value value="687365"/>
      <value value="9746514"/>
      <value value="638902"/>
      <value value="7807340"/>
      <value value="4768642"/>
      <value value="9037162"/>
      <value value="6479193"/>
      <value value="3053388"/>
      <value value="7759636"/>
      <value value="8171441"/>
      <value value="7221451"/>
      <value value="7791476"/>
      <value value="5159683"/>
      <value value="3153806"/>
      <value value="3899298"/>
      <value value="4997116"/>
      <value value="3262953"/>
      <value value="1922943"/>
      <value value="5162009"/>
      <value value="4571303"/>
      <value value="5195649"/>
      <value value="7705146"/>
      <value value="4695957"/>
      <value value="3573094"/>
      <value value="8571333"/>
      <value value="5767004"/>
      <value value="1018105"/>
      <value value="2057270"/>
      <value value="6251180"/>
      <value value="3662414"/>
      <value value="6957610"/>
      <value value="8005407"/>
      <value value="5651687"/>
      <value value="1123898"/>
      <value value="4580490"/>
      <value value="8768874"/>
      <value value="5313175"/>
      <value value="5751633"/>
      <value value="2286340"/>
      <value value="1721591"/>
      <value value="1008637"/>
      <value value="3921096"/>
      <value value="8266891"/>
      <value value="7078463"/>
      <value value="3974562"/>
      <value value="4579183"/>
      <value value="8144516"/>
      <value value="7273903"/>
      <value value="2205175"/>
      <value value="2549650"/>
      <value value="220106"/>
      <value value="6332402"/>
      <value value="6543423"/>
      <value value="6503597"/>
      <value value="1286161"/>
      <value value="5556230"/>
      <value value="3903934"/>
      <value value="4061241"/>
      <value value="1328975"/>
      <value value="3875135"/>
      <value value="6213135"/>
      <value value="4704932"/>
      <value value="2651787"/>
      <value value="4734083"/>
      <value value="995747"/>
      <value value="4596061"/>
      <value value="9407515"/>
      <value value="7935430"/>
      <value value="706924"/>
      <value value="3972383"/>
      <value value="7742897"/>
      <value value="9622133"/>
      <value value="430985"/>
      <value value="501933"/>
      <value value="6851443"/>
      <value value="6551085"/>
      <value value="77051"/>
      <value value="116501"/>
      <value value="7386318"/>
      <value value="1421826"/>
      <value value="1422117"/>
      <value value="2298267"/>
      <value value="4372933"/>
      <value value="2091453"/>
      <value value="9319538"/>
      <value value="6525680"/>
      <value value="9833322"/>
      <value value="3674077"/>
      <value value="4972082"/>
      <value value="6618015"/>
      <value value="9508274"/>
      <value value="2546336"/>
      <value value="2131273"/>
      <value value="1856317"/>
      <value value="6459122"/>
      <value value="5300290"/>
      <value value="9777896"/>
      <value value="9995179"/>
      <value value="2387446"/>
      <value value="7601422"/>
      <value value="4113421"/>
      <value value="6183824"/>
      <value value="3309771"/>
      <value value="3958404"/>
      <value value="2963605"/>
      <value value="2631852"/>
      <value value="462030"/>
      <value value="6744031"/>
      <value value="7505880"/>
      <value value="5917683"/>
      <value value="2247090"/>
      <value value="4193961"/>
      <value value="2248239"/>
      <value value="8319344"/>
      <value value="1430739"/>
      <value value="5229096"/>
      <value value="6722863"/>
      <value value="9086637"/>
      <value value="34482"/>
      <value value="5955671"/>
      <value value="641440"/>
      <value value="9379203"/>
      <value value="926271"/>
      <value value="6667728"/>
      <value value="9709791"/>
      <value value="6087636"/>
      <value value="4661563"/>
      <value value="3635261"/>
      <value value="730206"/>
      <value value="5874859"/>
      <value value="4226621"/>
      <value value="7114114"/>
      <value value="6415243"/>
      <value value="74347"/>
      <value value="8163112"/>
      <value value="7374261"/>
      <value value="5619657"/>
      <value value="9381328"/>
      <value value="7801911"/>
      <value value="5370168"/>
      <value value="6702201"/>
      <value value="8071418"/>
      <value value="1300676"/>
      <value value="3548518"/>
      <value value="3775507"/>
      <value value="5989989"/>
      <value value="2330683"/>
      <value value="4444954"/>
      <value value="7448662"/>
      <value value="6783064"/>
      <value value="9895614"/>
      <value value="8848843"/>
      <value value="8330774"/>
      <value value="135942"/>
      <value value="7113212"/>
      <value value="4104290"/>
      <value value="3715442"/>
      <value value="8915412"/>
      <value value="6514672"/>
      <value value="4658913"/>
      <value value="9487313"/>
      <value value="8829250"/>
      <value value="9001863"/>
      <value value="9292677"/>
      <value value="1916060"/>
      <value value="2078215"/>
      <value value="7710724"/>
      <value value="6285583"/>
      <value value="4320618"/>
      <value value="5895010"/>
      <value value="587230"/>
      <value value="3895229"/>
      <value value="7287619"/>
      <value value="5781885"/>
      <value value="651176"/>
      <value value="5150575"/>
      <value value="9674461"/>
      <value value="2655390"/>
      <value value="345268"/>
      <value value="8901340"/>
      <value value="1223314"/>
      <value value="101430"/>
      <value value="5425852"/>
      <value value="7472030"/>
      <value value="6811974"/>
      <value value="1570341"/>
      <value value="5342546"/>
      <value value="2270099"/>
      <value value="2226197"/>
      <value value="3437048"/>
      <value value="6908350"/>
      <value value="7570561"/>
      <value value="8988677"/>
      <value value="3733174"/>
      <value value="8015132"/>
      <value value="8439283"/>
      <value value="2065462"/>
      <value value="6308011"/>
      <value value="9707644"/>
      <value value="8313203"/>
      <value value="8210504"/>
      <value value="4945636"/>
      <value value="6894964"/>
      <value value="9161524"/>
      <value value="6000146"/>
      <value value="9509366"/>
      <value value="832479"/>
      <value value="3604217"/>
      <value value="959257"/>
      <value value="4064640"/>
      <value value="4930452"/>
      <value value="4265772"/>
      <value value="8965808"/>
      <value value="1388832"/>
      <value value="8895384"/>
      <value value="6870628"/>
      <value value="4117898"/>
      <value value="3851876"/>
      <value value="2401363"/>
      <value value="6771530"/>
      <value value="4829995"/>
      <value value="7478084"/>
      <value value="3752894"/>
      <value value="6326412"/>
      <value value="4443205"/>
      <value value="8655589"/>
      <value value="8149913"/>
      <value value="3754764"/>
      <value value="6693068"/>
      <value value="3010401"/>
      <value value="9972320"/>
      <value value="3503353"/>
      <value value="1400983"/>
      <value value="6293059"/>
      <value value="4946213"/>
      <value value="360679"/>
      <value value="9915846"/>
      <value value="8950765"/>
      <value value="2830393"/>
      <value value="9116869"/>
      <value value="7244632"/>
      <value value="512072"/>
      <value value="2771142"/>
      <value value="7601149"/>
      <value value="4816908"/>
      <value value="5444268"/>
      <value value="8925699"/>
      <value value="3698324"/>
      <value value="9716983"/>
      <value value="691970"/>
      <value value="7028236"/>
      <value value="271409"/>
      <value value="5412382"/>
      <value value="2351619"/>
      <value value="6903587"/>
      <value value="1838180"/>
      <value value="7206051"/>
      <value value="350309"/>
      <value value="7361401"/>
      <value value="1557193"/>
      <value value="8901105"/>
      <value value="1788008"/>
      <value value="9064967"/>
      <value value="1970177"/>
      <value value="2695669"/>
      <value value="2601909"/>
      <value value="3853484"/>
      <value value="8125892"/>
      <value value="6912745"/>
      <value value="9962268"/>
      <value value="3447898"/>
      <value value="6622339"/>
      <value value="819747"/>
      <value value="5854124"/>
      <value value="8518216"/>
      <value value="9375089"/>
      <value value="4048650"/>
      <value value="7791483"/>
      <value value="5757390"/>
      <value value="3064437"/>
      <value value="7174996"/>
      <value value="8473614"/>
      <value value="3749771"/>
      <value value="3181650"/>
      <value value="5590148"/>
      <value value="7625492"/>
      <value value="1496354"/>
      <value value="1601208"/>
      <value value="4883598"/>
      <value value="483586"/>
      <value value="5774938"/>
      <value value="3496192"/>
      <value value="3041485"/>
      <value value="3544588"/>
      <value value="1138622"/>
      <value value="3358820"/>
      <value value="3776481"/>
      <value value="463865"/>
      <value value="3252407"/>
      <value value="718781"/>
      <value value="4524209"/>
      <value value="6418092"/>
      <value value="8462592"/>
      <value value="7192813"/>
      <value value="9302221"/>
      <value value="876148"/>
      <value value="7102977"/>
      <value value="5161201"/>
      <value value="5462691"/>
      <value value="9142914"/>
      <value value="461111"/>
      <value value="5540164"/>
      <value value="8184040"/>
      <value value="7638821"/>
      <value value="2095728"/>
      <value value="5371960"/>
      <value value="7360242"/>
      <value value="2080447"/>
      <value value="7025170"/>
      <value value="3088506"/>
      <value value="8877973"/>
      <value value="6697824"/>
      <value value="8599622"/>
      <value value="5841211"/>
      <value value="373938"/>
      <value value="8379088"/>
      <value value="9326617"/>
      <value value="3022116"/>
      <value value="8225935"/>
      <value value="6174003"/>
      <value value="6109674"/>
      <value value="2044338"/>
      <value value="8623138"/>
      <value value="4807048"/>
      <value value="3787629"/>
      <value value="3313380"/>
      <value value="2299640"/>
      <value value="3942623"/>
      <value value="8287931"/>
      <value value="3863292"/>
      <value value="9209607"/>
      <value value="4199231"/>
      <value value="4157507"/>
      <value value="9191677"/>
      <value value="4252846"/>
      <value value="2294664"/>
      <value value="9080030"/>
      <value value="2823531"/>
      <value value="1845128"/>
      <value value="159776"/>
      <value value="2220705"/>
      <value value="5387584"/>
      <value value="3042768"/>
      <value value="7777103"/>
      <value value="3197984"/>
      <value value="4173251"/>
      <value value="3532264"/>
      <value value="8264651"/>
      <value value="7583848"/>
      <value value="2207465"/>
      <value value="1442621"/>
      <value value="9765560"/>
      <value value="1177258"/>
      <value value="9346419"/>
      <value value="1320724"/>
      <value value="4990400"/>
      <value value="3742456"/>
      <value value="457130"/>
      <value value="4642878"/>
      <value value="7232751"/>
      <value value="4048382"/>
      <value value="8547636"/>
      <value value="3393205"/>
      <value value="1534514"/>
      <value value="5230502"/>
      <value value="5628793"/>
      <value value="8511657"/>
      <value value="2050173"/>
      <value value="5445219"/>
      <value value="7363965"/>
      <value value="5649833"/>
      <value value="1916573"/>
      <value value="5169995"/>
      <value value="6414043"/>
      <value value="7414044"/>
      <value value="7835637"/>
      <value value="5357270"/>
      <value value="1538824"/>
      <value value="1916117"/>
      <value value="6662631"/>
      <value value="5848166"/>
      <value value="349684"/>
      <value value="6043775"/>
      <value value="2610643"/>
      <value value="3043875"/>
      <value value="5242376"/>
      <value value="6687178"/>
      <value value="8423215"/>
      <value value="4508017"/>
      <value value="6380215"/>
      <value value="6111388"/>
      <value value="6521826"/>
      <value value="2386845"/>
      <value value="461492"/>
      <value value="1249736"/>
      <value value="4324136"/>
      <value value="5097060"/>
      <value value="3421497"/>
      <value value="4072165"/>
      <value value="9422549"/>
      <value value="4123436"/>
      <value value="8592061"/>
      <value value="8362283"/>
      <value value="1970207"/>
      <value value="1843910"/>
      <value value="1375122"/>
      <value value="1924733"/>
      <value value="1452625"/>
      <value value="3962990"/>
      <value value="6879316"/>
      <value value="7751241"/>
      <value value="1924800"/>
      <value value="3535413"/>
      <value value="2988935"/>
      <value value="2726133"/>
      <value value="4126010"/>
      <value value="3615399"/>
      <value value="8262285"/>
      <value value="9904919"/>
      <value value="1795316"/>
      <value value="438169"/>
      <value value="996086"/>
      <value value="1158061"/>
      <value value="5272742"/>
      <value value="1810134"/>
      <value value="6193163"/>
      <value value="3833810"/>
      <value value="6857188"/>
      <value value="7378701"/>
      <value value="6814617"/>
      <value value="7823602"/>
      <value value="4075753"/>
      <value value="5235796"/>
      <value value="4341581"/>
      <value value="6824386"/>
      <value value="9981989"/>
      <value value="4037042"/>
      <value value="1232120"/>
      <value value="7489508"/>
      <value value="3490742"/>
      <value value="4979356"/>
      <value value="8979731"/>
      <value value="4185335"/>
      <value value="7699251"/>
      <value value="3960584"/>
      <value value="9767917"/>
      <value value="2715390"/>
      <value value="8264"/>
      <value value="1080207"/>
      <value value="5886694"/>
      <value value="6660855"/>
      <value value="3437296"/>
      <value value="5322469"/>
      <value value="770973"/>
      <value value="1786852"/>
      <value value="1479324"/>
      <value value="3021051"/>
      <value value="9993564"/>
      <value value="9497702"/>
      <value value="3253351"/>
      <value value="6097132"/>
      <value value="4502808"/>
      <value value="5435469"/>
      <value value="7209093"/>
      <value value="2224885"/>
      <value value="463640"/>
      <value value="2683548"/>
      <value value="349203"/>
      <value value="1970172"/>
      <value value="2272436"/>
      <value value="3915436"/>
      <value value="4936806"/>
      <value value="1664457"/>
      <value value="9212368"/>
      <value value="8304069"/>
      <value value="2369772"/>
      <value value="5640785"/>
      <value value="5774972"/>
      <value value="775079"/>
      <value value="5069785"/>
      <value value="1398146"/>
      <value value="7762916"/>
      <value value="6593245"/>
      <value value="1545700"/>
      <value value="411786"/>
      <value value="5397485"/>
      <value value="9419534"/>
      <value value="3154651"/>
      <value value="4509898"/>
      <value value="1893721"/>
      <value value="6033475"/>
      <value value="5357916"/>
      <value value="8745080"/>
      <value value="3199447"/>
      <value value="9320255"/>
      <value value="5827527"/>
      <value value="9513270"/>
      <value value="8047399"/>
      <value value="6670203"/>
      <value value="5103289"/>
      <value value="2086487"/>
      <value value="6177333"/>
      <value value="1974513"/>
      <value value="7770454"/>
      <value value="349272"/>
      <value value="322121"/>
      <value value="9962924"/>
      <value value="5932494"/>
      <value value="4233105"/>
      <value value="9994913"/>
      <value value="6616364"/>
      <value value="8997172"/>
      <value value="5064372"/>
      <value value="4893684"/>
      <value value="6378392"/>
      <value value="9527751"/>
      <value value="8423691"/>
      <value value="3825552"/>
      <value value="4478698"/>
      <value value="3864351"/>
      <value value="7366119"/>
      <value value="3647533"/>
      <value value="7785464"/>
      <value value="331994"/>
      <value value="3695149"/>
      <value value="4402937"/>
      <value value="8792802"/>
      <value value="8777171"/>
      <value value="9308815"/>
      <value value="1572833"/>
      <value value="9818083"/>
      <value value="6583358"/>
      <value value="4711467"/>
      <value value="8680933"/>
      <value value="9376501"/>
      <value value="5118637"/>
      <value value="6489232"/>
      <value value="7382354"/>
      <value value="5248041"/>
      <value value="208442"/>
      <value value="8042704"/>
      <value value="8879796"/>
      <value value="2803952"/>
      <value value="999025"/>
      <value value="4911200"/>
      <value value="5887119"/>
      <value value="4389201"/>
      <value value="1150651"/>
      <value value="6485042"/>
      <value value="5557984"/>
      <value value="9520112"/>
      <value value="7763616"/>
      <value value="3603879"/>
      <value value="7809605"/>
      <value value="6096316"/>
      <value value="8203940"/>
      <value value="5776466"/>
      <value value="1894927"/>
      <value value="252398"/>
      <value value="5783363"/>
      <value value="3920055"/>
      <value value="4459170"/>
      <value value="7575924"/>
      <value value="7953379"/>
      <value value="6157484"/>
      <value value="1973390"/>
      <value value="3744985"/>
      <value value="3541344"/>
      <value value="7054809"/>
      <value value="9440976"/>
      <value value="3224162"/>
      <value value="8299847"/>
      <value value="1368614"/>
      <value value="7212199"/>
      <value value="8407321"/>
      <value value="279871"/>
      <value value="8563477"/>
      <value value="4698248"/>
      <value value="2026357"/>
      <value value="3409181"/>
      <value value="8090644"/>
      <value value="9400320"/>
      <value value="1852605"/>
      <value value="6919225"/>
      <value value="5603562"/>
      <value value="1184638"/>
      <value value="4801039"/>
      <value value="622791"/>
      <value value="6119614"/>
      <value value="3602776"/>
      <value value="7019749"/>
      <value value="4057308"/>
      <value value="6525490"/>
      <value value="1665575"/>
      <value value="326737"/>
      <value value="3915114"/>
      <value value="4537342"/>
      <value value="8381694"/>
      <value value="9685400"/>
      <value value="777437"/>
      <value value="710537"/>
      <value value="4925997"/>
      <value value="8064528"/>
      <value value="8231831"/>
      <value value="3115076"/>
      <value value="6538550"/>
      <value value="8892783"/>
      <value value="4094018"/>
      <value value="6852248"/>
      <value value="7558749"/>
      <value value="6632753"/>
      <value value="2380645"/>
      <value value="576512"/>
      <value value="6911239"/>
      <value value="9930495"/>
      <value value="4989929"/>
      <value value="4215544"/>
      <value value="6147083"/>
      <value value="8789698"/>
      <value value="7581336"/>
      <value value="3959660"/>
      <value value="5714906"/>
      <value value="6805394"/>
      <value value="22811"/>
      <value value="634183"/>
      <value value="7541589"/>
      <value value="5681288"/>
      <value value="6818050"/>
      <value value="3275204"/>
      <value value="4137848"/>
      <value value="9820730"/>
      <value value="1149745"/>
      <value value="9105616"/>
      <value value="5817845"/>
      <value value="7397006"/>
      <value value="8641793"/>
      <value value="4586829"/>
      <value value="7036013"/>
      <value value="3572798"/>
      <value value="6524151"/>
      <value value="3493472"/>
      <value value="2857761"/>
      <value value="3992779"/>
      <value value="7243800"/>
      <value value="2062827"/>
      <value value="3889749"/>
      <value value="9508525"/>
      <value value="5167529"/>
      <value value="1052472"/>
      <value value="8448891"/>
      <value value="9955874"/>
      <value value="9834038"/>
      <value value="7964890"/>
      <value value="9021972"/>
      <value value="2487603"/>
      <value value="4031435"/>
      <value value="8247630"/>
      <value value="1929237"/>
      <value value="3643445"/>
      <value value="7218756"/>
      <value value="4997527"/>
      <value value="3425676"/>
      <value value="7987230"/>
      <value value="9702660"/>
      <value value="3533024"/>
      <value value="1860762"/>
      <value value="4318272"/>
      <value value="9592137"/>
      <value value="7792957"/>
      <value value="422986"/>
      <value value="1474666"/>
      <value value="1522403"/>
      <value value="4053107"/>
      <value value="3364294"/>
      <value value="1333879"/>
      <value value="5497647"/>
      <value value="2936709"/>
      <value value="9235769"/>
      <value value="1499015"/>
      <value value="5758446"/>
      <value value="9143192"/>
      <value value="3147582"/>
      <value value="621923"/>
      <value value="9949413"/>
      <value value="3462473"/>
      <value value="2538581"/>
      <value value="7904551"/>
      <value value="9713831"/>
      <value value="5323345"/>
      <value value="4269713"/>
      <value value="2806915"/>
      <value value="2398851"/>
      <value value="6915364"/>
      <value value="1812832"/>
      <value value="7182351"/>
      <value value="8534882"/>
      <value value="2254908"/>
      <value value="86291"/>
      <value value="6367603"/>
      <value value="8418404"/>
      <value value="1582148"/>
      <value value="4888978"/>
      <value value="9798712"/>
      <value value="1438866"/>
      <value value="1585674"/>
      <value value="6854599"/>
      <value value="1860592"/>
      <value value="6801414"/>
      <value value="7455698"/>
      <value value="8821694"/>
      <value value="780406"/>
      <value value="2472741"/>
      <value value="9855872"/>
      <value value="9509460"/>
      <value value="1867080"/>
      <value value="5689577"/>
      <value value="2011239"/>
      <value value="9956351"/>
      <value value="1098301"/>
      <value value="8409132"/>
      <value value="6679663"/>
      <value value="2046167"/>
      <value value="2480708"/>
      <value value="3967493"/>
      <value value="2713372"/>
      <value value="9690715"/>
      <value value="3220565"/>
      <value value="7182474"/>
      <value value="8825973"/>
      <value value="9256086"/>
      <value value="6923927"/>
      <value value="4310991"/>
      <value value="4614555"/>
      <value value="5363304"/>
      <value value="5018074"/>
      <value value="745177"/>
      <value value="4135442"/>
      <value value="4145589"/>
      <value value="4566618"/>
      <value value="4366003"/>
      <value value="4235000"/>
      <value value="7897144"/>
      <value value="1142560"/>
      <value value="4825625"/>
      <value value="1059047"/>
      <value value="4839605"/>
      <value value="1050865"/>
      <value value="6389003"/>
      <value value="7290273"/>
      <value value="9338067"/>
      <value value="9015185"/>
      <value value="8338052"/>
      <value value="148761"/>
      <value value="2840952"/>
      <value value="6665735"/>
      <value value="4916956"/>
      <value value="1260421"/>
      <value value="8392731"/>
      <value value="8798044"/>
      <value value="8888025"/>
      <value value="1547066"/>
      <value value="392620"/>
      <value value="1867994"/>
      <value value="1784416"/>
      <value value="7481542"/>
      <value value="6019840"/>
      <value value="1490338"/>
      <value value="3631851"/>
      <value value="8812291"/>
      <value value="216182"/>
      <value value="8348835"/>
      <value value="2870095"/>
      <value value="8414751"/>
      <value value="3090797"/>
      <value value="101205"/>
      <value value="1685060"/>
      <value value="3008746"/>
      <value value="2156767"/>
      <value value="777480"/>
      <value value="1934285"/>
      <value value="8984892"/>
      <value value="1516420"/>
      <value value="1853451"/>
      <value value="474119"/>
      <value value="4971947"/>
      <value value="1614360"/>
      <value value="5788011"/>
      <value value="8615155"/>
      <value value="8672623"/>
      <value value="9363059"/>
      <value value="8826437"/>
      <value value="2928027"/>
      <value value="7807468"/>
      <value value="3329316"/>
      <value value="3999592"/>
      <value value="5756036"/>
      <value value="8962724"/>
      <value value="8913709"/>
      <value value="4429125"/>
      <value value="3244537"/>
      <value value="5928828"/>
      <value value="6444884"/>
      <value value="847433"/>
      <value value="99192"/>
      <value value="3689235"/>
      <value value="7264672"/>
      <value value="6298424"/>
      <value value="5294610"/>
      <value value="667662"/>
      <value value="4296225"/>
      <value value="2797728"/>
      <value value="8890343"/>
      <value value="2517797"/>
      <value value="3759779"/>
      <value value="3530702"/>
      <value value="1754878"/>
      <value value="6346930"/>
      <value value="5430658"/>
      <value value="4207896"/>
      <value value="7840291"/>
      <value value="5025973"/>
      <value value="879036"/>
      <value value="1129819"/>
      <value value="8593667"/>
      <value value="6867017"/>
      <value value="2124829"/>
      <value value="8639952"/>
      <value value="981637"/>
      <value value="9215794"/>
      <value value="2820232"/>
      <value value="9097378"/>
      <value value="3658173"/>
      <value value="6495901"/>
      <value value="413748"/>
      <value value="7832585"/>
      <value value="770806"/>
      <value value="3282948"/>
      <value value="3210860"/>
      <value value="524234"/>
      <value value="9687746"/>
      <value value="5876076"/>
      <value value="7602092"/>
      <value value="377908"/>
      <value value="898401"/>
      <value value="6803236"/>
      <value value="4210735"/>
      <value value="5396642"/>
      <value value="8122813"/>
      <value value="4351050"/>
      <value value="1688791"/>
      <value value="2650516"/>
      <value value="136541"/>
      <value value="2584900"/>
      <value value="7195248"/>
      <value value="7615792"/>
      <value value="4445008"/>
      <value value="5820613"/>
      <value value="8549197"/>
      <value value="4819153"/>
      <value value="9588256"/>
      <value value="7840093"/>
      <value value="3502366"/>
      <value value="2131627"/>
      <value value="1879747"/>
      <value value="7911700"/>
      <value value="9914640"/>
      <value value="9779732"/>
      <value value="7779433"/>
      <value value="4774948"/>
      <value value="1617916"/>
      <value value="6184526"/>
      <value value="5794466"/>
      <value value="2010846"/>
      <value value="9549207"/>
      <value value="5716123"/>
      <value value="2116971"/>
      <value value="5055581"/>
      <value value="443889"/>
      <value value="504465"/>
      <value value="6951292"/>
      <value value="5572101"/>
      <value value="4603604"/>
      <value value="5896214"/>
      <value value="7275186"/>
      <value value="2859770"/>
      <value value="8712227"/>
      <value value="6850812"/>
      <value value="1524278"/>
      <value value="7761644"/>
      <value value="8731728"/>
      <value value="9968656"/>
      <value value="3794558"/>
      <value value="6468982"/>
      <value value="8921595"/>
      <value value="9521103"/>
      <value value="2442117"/>
      <value value="2488696"/>
      <value value="2129865"/>
      <value value="7396034"/>
      <value value="8986202"/>
      <value value="9627588"/>
      <value value="9995566"/>
      <value value="5451858"/>
      <value value="966528"/>
      <value value="5876364"/>
      <value value="4990903"/>
      <value value="5376422"/>
      <value value="6083859"/>
      <value value="2240823"/>
      <value value="3369786"/>
      <value value="4136240"/>
      <value value="7790830"/>
      <value value="4360141"/>
      <value value="8148254"/>
      <value value="8503805"/>
      <value value="6977238"/>
      <value value="3774409"/>
      <value value="5779801"/>
      <value value="4663114"/>
      <value value="8604341"/>
      <value value="5266586"/>
      <value value="9202366"/>
      <value value="7961652"/>
      <value value="1130004"/>
      <value value="2521749"/>
      <value value="5011006"/>
      <value value="9983978"/>
      <value value="446585"/>
      <value value="6638285"/>
      <value value="4587114"/>
      <value value="3467915"/>
      <value value="9360802"/>
      <value value="9869202"/>
      <value value="1928732"/>
      <value value="1537321"/>
      <value value="5760580"/>
      <value value="4810061"/>
      <value value="1497984"/>
      <value value="376975"/>
      <value value="4662136"/>
      <value value="259408"/>
      <value value="5631627"/>
      <value value="3443678"/>
      <value value="2222276"/>
      <value value="9871922"/>
      <value value="467518"/>
      <value value="9201325"/>
      <value value="5710742"/>
      <value value="3860423"/>
      <value value="163897"/>
      <value value="7960467"/>
      <value value="9817698"/>
      <value value="2492725"/>
      <value value="6713697"/>
      <value value="5126314"/>
      <value value="8814250"/>
      <value value="8859216"/>
      <value value="923121"/>
      <value value="5660489"/>
      <value value="2017974"/>
      <value value="2939043"/>
      <value value="349247"/>
      <value value="1385836"/>
      <value value="964436"/>
      <value value="4984129"/>
      <value value="8688073"/>
      <value value="3429476"/>
      <value value="2653144"/>
      <value value="8221012"/>
      <value value="2224809"/>
      <value value="8391110"/>
      <value value="9424072"/>
      <value value="6920449"/>
      <value value="9151334"/>
      <value value="6976433"/>
      <value value="8841632"/>
      <value value="8502813"/>
      <value value="226016"/>
      <value value="172077"/>
      <value value="5308295"/>
      <value value="7288220"/>
      <value value="8363559"/>
      <value value="2500774"/>
      <value value="5395695"/>
      <value value="9580546"/>
      <value value="516111"/>
      <value value="7704408"/>
      <value value="9131746"/>
      <value value="2402278"/>
      <value value="9023126"/>
      <value value="7555705"/>
      <value value="8678522"/>
      <value value="305324"/>
      <value value="1798349"/>
      <value value="301738"/>
      <value value="3494856"/>
      <value value="7281118"/>
      <value value="8474192"/>
      <value value="289686"/>
      <value value="7858334"/>
      <value value="4698469"/>
      <value value="7472665"/>
      <value value="831345"/>
      <value value="782089"/>
      <value value="8787718"/>
      <value value="9359559"/>
      <value value="9972433"/>
      <value value="2903274"/>
      <value value="7876726"/>
      <value value="7047891"/>
      <value value="6800261"/>
      <value value="2471649"/>
      <value value="4659995"/>
      <value value="5605875"/>
      <value value="4623632"/>
      <value value="2822512"/>
      <value value="1164876"/>
      <value value="1016157"/>
      <value value="8980193"/>
      <value value="4060201"/>
      <value value="1851616"/>
      <value value="8127806"/>
      <value value="3665969"/>
      <value value="2230951"/>
      <value value="3593895"/>
      <value value="8390945"/>
      <value value="5500191"/>
      <value value="7033032"/>
      <value value="6946388"/>
      <value value="150478"/>
      <value value="100278"/>
      <value value="8482893"/>
      <value value="8435952"/>
      <value value="6271788"/>
      <value value="5013144"/>
      <value value="7019313"/>
      <value value="7157560"/>
      <value value="2222656"/>
      <value value="6100709"/>
      <value value="6410338"/>
      <value value="6916593"/>
      <value value="4142739"/>
      <value value="3140110"/>
      <value value="6492839"/>
      <value value="3425939"/>
      <value value="7268368"/>
      <value value="1767963"/>
      <value value="2440616"/>
      <value value="3960582"/>
      <value value="431830"/>
      <value value="6957617"/>
      <value value="6553442"/>
      <value value="4249860"/>
      <value value="198153"/>
      <value value="552695"/>
      <value value="6446792"/>
      <value value="330831"/>
      <value value="9108004"/>
      <value value="8707192"/>
      <value value="3562150"/>
      <value value="8435144"/>
      <value value="4942877"/>
      <value value="6519176"/>
      <value value="7666137"/>
      <value value="5505681"/>
      <value value="6412074"/>
      <value value="3126401"/>
      <value value="1282222"/>
      <value value="7002539"/>
      <value value="6390565"/>
      <value value="6802873"/>
      <value value="2306226"/>
      <value value="643270"/>
      <value value="6993003"/>
      <value value="2685608"/>
      <value value="6861601"/>
      <value value="8396898"/>
      <value value="1327384"/>
      <value value="9111549"/>
      <value value="9356322"/>
      <value value="8858027"/>
      <value value="1070067"/>
      <value value="5368650"/>
      <value value="9012108"/>
      <value value="9932523"/>
      <value value="4272554"/>
      <value value="7034237"/>
      <value value="387876"/>
      <value value="3315753"/>
      <value value="7174875"/>
      <value value="8923180"/>
      <value value="9279010"/>
      <value value="1406181"/>
      <value value="7000034"/>
      <value value="3983127"/>
      <value value="9224944"/>
      <value value="4080003"/>
      <value value="6328493"/>
      <value value="5810139"/>
      <value value="7304367"/>
      <value value="3936591"/>
      <value value="6755627"/>
      <value value="9859811"/>
      <value value="6041858"/>
      <value value="9451889"/>
      <value value="8749364"/>
      <value value="4436148"/>
      <value value="1287186"/>
      <value value="211787"/>
      <value value="9569813"/>
      <value value="633138"/>
      <value value="1926601"/>
      <value value="7601567"/>
      <value value="5470665"/>
      <value value="9011661"/>
      <value value="1829593"/>
      <value value="858555"/>
      <value value="5147413"/>
      <value value="7992629"/>
      <value value="6654782"/>
      <value value="3381695"/>
      <value value="4158208"/>
      <value value="8051123"/>
      <value value="9742618"/>
      <value value="5275377"/>
      <value value="3424978"/>
      <value value="9383501"/>
      <value value="7370888"/>
      <value value="2874312"/>
      <value value="9546130"/>
      <value value="2211896"/>
      <value value="6880615"/>
      <value value="2429153"/>
      <value value="9982120"/>
      <value value="2446902"/>
      <value value="2999496"/>
      <value value="6627273"/>
      <value value="3877150"/>
      <value value="9911376"/>
      <value value="6402406"/>
      <value value="4779261"/>
      <value value="7622529"/>
      <value value="8775177"/>
      <value value="7570386"/>
      <value value="6219443"/>
      <value value="7933789"/>
      <value value="6237150"/>
      <value value="6351756"/>
      <value value="4852775"/>
      <value value="9602107"/>
      <value value="528941"/>
      <value value="2215083"/>
      <value value="4767613"/>
      <value value="713816"/>
      <value value="9821500"/>
      <value value="7711032"/>
      <value value="241233"/>
      <value value="2193679"/>
      <value value="7794220"/>
      <value value="8201755"/>
      <value value="678239"/>
      <value value="5331166"/>
      <value value="295971"/>
      <value value="1770574"/>
      <value value="8141461"/>
      <value value="3683686"/>
      <value value="7652721"/>
      <value value="7214936"/>
      <value value="4791036"/>
      <value value="7068246"/>
      <value value="3452101"/>
      <value value="463458"/>
      <value value="9157967"/>
      <value value="2712928"/>
      <value value="5503583"/>
      <value value="5970759"/>
      <value value="3559537"/>
      <value value="3670404"/>
      <value value="6823198"/>
      <value value="8505514"/>
      <value value="1152152"/>
      <value value="5957484"/>
      <value value="111706"/>
      <value value="78309"/>
      <value value="3899704"/>
      <value value="7393194"/>
      <value value="3565559"/>
      <value value="327091"/>
      <value value="1910784"/>
      <value value="5437537"/>
      <value value="4396623"/>
      <value value="9915257"/>
      <value value="319734"/>
      <value value="1792057"/>
      <value value="6203959"/>
      <value value="5113760"/>
      <value value="6335210"/>
      <value value="6315031"/>
      <value value="5748030"/>
      <value value="4144015"/>
      <value value="2030647"/>
      <value value="7382870"/>
      <value value="8669727"/>
      <value value="824936"/>
      <value value="8787653"/>
      <value value="3343086"/>
      <value value="3201045"/>
      <value value="3753282"/>
      <value value="2037872"/>
      <value value="9096666"/>
      <value value="2058801"/>
      <value value="3819638"/>
      <value value="6411779"/>
      <value value="3324097"/>
      <value value="5597763"/>
      <value value="7278459"/>
      <value value="9942876"/>
      <value value="4183763"/>
      <value value="8203502"/>
      <value value="5136543"/>
      <value value="1790210"/>
      <value value="4241200"/>
      <value value="242539"/>
      <value value="6259386"/>
      <value value="8816084"/>
      <value value="6772332"/>
      <value value="8571183"/>
      <value value="354656"/>
      <value value="8548697"/>
      <value value="7282036"/>
      <value value="3276795"/>
      <value value="6521786"/>
      <value value="3318536"/>
      <value value="5335385"/>
      <value value="5938055"/>
      <value value="9190681"/>
      <value value="8447629"/>
      <value value="73472"/>
      <value value="1195493"/>
      <value value="900574"/>
      <value value="444845"/>
      <value value="5961544"/>
      <value value="5650298"/>
      <value value="7889724"/>
      <value value="1326804"/>
      <value value="2297847"/>
      <value value="8770335"/>
      <value value="6403128"/>
      <value value="4219550"/>
      <value value="1593803"/>
      <value value="110125"/>
      <value value="1779641"/>
      <value value="5827279"/>
      <value value="1845299"/>
      <value value="256947"/>
      <value value="7171414"/>
      <value value="287304"/>
      <value value="7350753"/>
      <value value="1903795"/>
      <value value="1243882"/>
      <value value="383449"/>
      <value value="7482271"/>
      <value value="2691542"/>
      <value value="7767803"/>
      <value value="3514274"/>
      <value value="3693964"/>
      <value value="8584702"/>
      <value value="60159"/>
      <value value="8321477"/>
      <value value="3902166"/>
      <value value="652769"/>
      <value value="238673"/>
      <value value="5871445"/>
      <value value="2128099"/>
      <value value="8703610"/>
      <value value="5166546"/>
      <value value="3311251"/>
      <value value="1566301"/>
      <value value="697480"/>
      <value value="8258948"/>
      <value value="1834207"/>
      <value value="8012942"/>
      <value value="29767"/>
      <value value="3238106"/>
      <value value="4854680"/>
      <value value="2382762"/>
      <value value="6049308"/>
      <value value="2137195"/>
      <value value="9947199"/>
      <value value="3365460"/>
      <value value="646131"/>
      <value value="3474327"/>
      <value value="7161235"/>
      <value value="9186213"/>
      <value value="7395224"/>
      <value value="7157421"/>
      <value value="9558837"/>
      <value value="5071079"/>
      <value value="8389837"/>
      <value value="7617727"/>
      <value value="5608020"/>
      <value value="2563082"/>
      <value value="4690162"/>
      <value value="6766795"/>
      <value value="9426223"/>
      <value value="6448429"/>
      <value value="8193225"/>
      <value value="8689549"/>
      <value value="8548185"/>
      <value value="2361305"/>
      <value value="9430647"/>
      <value value="463182"/>
      <value value="4220221"/>
      <value value="6211500"/>
      <value value="8966910"/>
      <value value="5390831"/>
      <value value="9765768"/>
      <value value="9897431"/>
      <value value="8811098"/>
      <value value="1506530"/>
      <value value="4364855"/>
      <value value="1719437"/>
      <value value="1002003"/>
      <value value="743750"/>
      <value value="2662646"/>
      <value value="8396953"/>
      <value value="8063896"/>
      <value value="9849223"/>
      <value value="9675726"/>
      <value value="4929940"/>
      <value value="7596540"/>
      <value value="6744640"/>
      <value value="9916683"/>
      <value value="1936095"/>
      <value value="8578671"/>
      <value value="9327339"/>
      <value value="2915402"/>
      <value value="9503799"/>
      <value value="6382052"/>
      <value value="795104"/>
      <value value="8395611"/>
      <value value="6183329"/>
      <value value="98955"/>
      <value value="8972335"/>
      <value value="2495330"/>
      <value value="5917613"/>
      <value value="3664299"/>
      <value value="6912931"/>
      <value value="6475010"/>
      <value value="4704065"/>
      <value value="6499211"/>
      <value value="4737849"/>
      <value value="4865330"/>
      <value value="8623683"/>
      <value value="7216043"/>
      <value value="2562142"/>
      <value value="806159"/>
      <value value="7913086"/>
      <value value="7452208"/>
      <value value="900810"/>
      <value value="9815827"/>
      <value value="9508205"/>
      <value value="3374744"/>
      <value value="9590477"/>
      <value value="9874745"/>
      <value value="6188696"/>
      <value value="6517654"/>
      <value value="6799347"/>
      <value value="8427402"/>
      <value value="4177858"/>
      <value value="7657520"/>
      <value value="8919594"/>
      <value value="911537"/>
      <value value="7886312"/>
      <value value="586216"/>
      <value value="322829"/>
      <value value="535916"/>
      <value value="9924817"/>
      <value value="9011254"/>
      <value value="5380692"/>
      <value value="8231782"/>
      <value value="3302889"/>
      <value value="7256720"/>
      <value value="4336179"/>
      <value value="5753589"/>
      <value value="4161440"/>
      <value value="8797377"/>
      <value value="6334703"/>
      <value value="9553774"/>
      <value value="669499"/>
      <value value="4793194"/>
      <value value="2275246"/>
      <value value="5198368"/>
      <value value="1542564"/>
      <value value="4163353"/>
      <value value="5924352"/>
      <value value="1332112"/>
      <value value="4467127"/>
      <value value="1445646"/>
      <value value="1145700"/>
      <value value="9344121"/>
      <value value="2773813"/>
      <value value="1914444"/>
      <value value="3113781"/>
      <value value="5642849"/>
      <value value="2686809"/>
      <value value="4517007"/>
      <value value="1798793"/>
      <value value="8916465"/>
      <value value="6509025"/>
      <value value="2524178"/>
      <value value="3217522"/>
      <value value="9051755"/>
      <value value="4740349"/>
      <value value="9277183"/>
      <value value="6900939"/>
      <value value="6553900"/>
      <value value="2452042"/>
      <value value="2345027"/>
      <value value="6832512"/>
      <value value="6575142"/>
      <value value="8362513"/>
      <value value="6604922"/>
      <value value="7267110"/>
      <value value="7534126"/>
      <value value="1627986"/>
      <value value="1555479"/>
      <value value="8393012"/>
      <value value="3604663"/>
      <value value="6571951"/>
      <value value="7224099"/>
      <value value="4591993"/>
      <value value="4161666"/>
      <value value="4140867"/>
      <value value="7236868"/>
      <value value="2762580"/>
      <value value="4815711"/>
      <value value="7382100"/>
      <value value="772523"/>
      <value value="1245770"/>
      <value value="2912247"/>
      <value value="3173249"/>
      <value value="8454406"/>
      <value value="2622636"/>
      <value value="3329993"/>
      <value value="9398981"/>
      <value value="8394099"/>
      <value value="4729832"/>
      <value value="6975858"/>
      <value value="6821046"/>
      <value value="5574075"/>
      <value value="5063680"/>
      <value value="2994437"/>
      <value value="8751036"/>
      <value value="1706618"/>
      <value value="6329674"/>
      <value value="2018954"/>
      <value value="2330509"/>
      <value value="1139233"/>
      <value value="5732650"/>
      <value value="3588492"/>
      <value value="4932410"/>
      <value value="8482586"/>
      <value value="4023981"/>
      <value value="4934970"/>
      <value value="328044"/>
      <value value="4080091"/>
      <value value="9953216"/>
      <value value="277407"/>
      <value value="1017736"/>
      <value value="212025"/>
      <value value="567326"/>
      <value value="8641983"/>
      <value value="5330990"/>
      <value value="1633654"/>
      <value value="8252535"/>
      <value value="3889845"/>
      <value value="5331146"/>
      <value value="5353898"/>
      <value value="1058691"/>
      <value value="1702139"/>
      <value value="6536046"/>
      <value value="3998722"/>
      <value value="4796776"/>
      <value value="2258971"/>
      <value value="4380215"/>
      <value value="4926594"/>
      <value value="1982231"/>
      <value value="6603583"/>
      <value value="5523207"/>
      <value value="5296924"/>
      <value value="8403791"/>
      <value value="3356423"/>
      <value value="8036038"/>
      <value value="8371223"/>
      <value value="9614066"/>
      <value value="9874728"/>
      <value value="7505291"/>
      <value value="2527712"/>
      <value value="6574282"/>
      <value value="93653"/>
      <value value="1877638"/>
      <value value="2744769"/>
      <value value="8497292"/>
      <value value="2820248"/>
      <value value="9121030"/>
      <value value="2080291"/>
      <value value="7482228"/>
      <value value="2348788"/>
      <value value="5934266"/>
      <value value="4991025"/>
      <value value="3301155"/>
      <value value="5450572"/>
      <value value="2555865"/>
      <value value="7347477"/>
      <value value="3338107"/>
      <value value="5093858"/>
      <value value="5652645"/>
      <value value="9009213"/>
      <value value="6227313"/>
      <value value="3718062"/>
      <value value="9495372"/>
      <value value="958686"/>
      <value value="9227154"/>
      <value value="1538055"/>
      <value value="7233546"/>
      <value value="5011264"/>
      <value value="3172299"/>
      <value value="5817549"/>
      <value value="7615866"/>
      <value value="3277192"/>
      <value value="5546713"/>
      <value value="3721092"/>
      <value value="3414827"/>
      <value value="4120943"/>
      <value value="4191221"/>
      <value value="7080342"/>
      <value value="3546518"/>
      <value value="5587704"/>
      <value value="5155394"/>
      <value value="6642963"/>
      <value value="638950"/>
      <value value="8802049"/>
      <value value="3300460"/>
      <value value="2579949"/>
      <value value="4963792"/>
      <value value="5880268"/>
      <value value="2068644"/>
      <value value="1003181"/>
      <value value="9635772"/>
      <value value="357061"/>
      <value value="7558853"/>
      <value value="3309569"/>
      <value value="1243482"/>
      <value value="4502795"/>
      <value value="898884"/>
      <value value="5245851"/>
      <value value="9113826"/>
      <value value="3912652"/>
      <value value="6091336"/>
      <value value="9777851"/>
      <value value="8225575"/>
      <value value="5420534"/>
      <value value="323509"/>
      <value value="4096984"/>
      <value value="5360904"/>
      <value value="3365092"/>
      <value value="6729949"/>
      <value value="1194796"/>
      <value value="7506985"/>
      <value value="5220283"/>
      <value value="2593230"/>
      <value value="1300909"/>
      <value value="5137534"/>
      <value value="3914219"/>
      <value value="1473519"/>
      <value value="3995458"/>
      <value value="8576928"/>
      <value value="203815"/>
      <value value="3183903"/>
      <value value="8406303"/>
      <value value="4997366"/>
      <value value="4137940"/>
      <value value="5574080"/>
      <value value="2910764"/>
      <value value="1681804"/>
      <value value="6736173"/>
      <value value="1610952"/>
      <value value="2139270"/>
      <value value="4381863"/>
      <value value="810137"/>
      <value value="1842858"/>
      <value value="9148602"/>
      <value value="4641591"/>
      <value value="9269970"/>
      <value value="7460351"/>
      <value value="7888623"/>
      <value value="9771057"/>
      <value value="3364510"/>
      <value value="3956787"/>
      <value value="1568098"/>
      <value value="6208399"/>
      <value value="2081663"/>
      <value value="8719902"/>
      <value value="7933449"/>
      <value value="3869290"/>
      <value value="9404667"/>
      <value value="2897608"/>
      <value value="3503822"/>
      <value value="391938"/>
      <value value="511060"/>
      <value value="8484941"/>
      <value value="1484029"/>
      <value value="280577"/>
      <value value="6963871"/>
      <value value="168960"/>
      <value value="6928752"/>
      <value value="4946975"/>
      <value value="5300620"/>
      <value value="783138"/>
      <value value="5367819"/>
      <value value="8497144"/>
      <value value="2350264"/>
      <value value="9258196"/>
      <value value="3791268"/>
      <value value="2083129"/>
      <value value="1020384"/>
      <value value="7750294"/>
      <value value="4990955"/>
      <value value="7000694"/>
      <value value="8567121"/>
      <value value="3725697"/>
      <value value="4661242"/>
      <value value="7069191"/>
      <value value="913005"/>
      <value value="1936963"/>
      <value value="1202317"/>
      <value value="6963461"/>
      <value value="5636107"/>
      <value value="7864770"/>
      <value value="1364940"/>
      <value value="2584953"/>
      <value value="1879652"/>
      <value value="2810276"/>
      <value value="3665833"/>
      <value value="4304683"/>
      <value value="8374434"/>
      <value value="8544005"/>
      <value value="3316002"/>
      <value value="4805538"/>
      <value value="3850495"/>
      <value value="3948733"/>
      <value value="9585453"/>
      <value value="6498294"/>
      <value value="745441"/>
      <value value="8270387"/>
      <value value="1388832"/>
      <value value="737171"/>
      <value value="8437272"/>
      <value value="9722986"/>
      <value value="5685389"/>
      <value value="6691692"/>
      <value value="9539390"/>
      <value value="6968942"/>
      <value value="1982019"/>
      <value value="3509687"/>
      <value value="7454869"/>
      <value value="5245496"/>
      <value value="6553883"/>
      <value value="6474800"/>
      <value value="120772"/>
      <value value="6757581"/>
      <value value="5444035"/>
      <value value="354171"/>
      <value value="7115752"/>
      <value value="8948349"/>
      <value value="3805940"/>
      <value value="559157"/>
      <value value="1277082"/>
      <value value="7552695"/>
      <value value="8113085"/>
      <value value="2149828"/>
      <value value="2741823"/>
      <value value="110489"/>
      <value value="2676044"/>
      <value value="937682"/>
      <value value="1042360"/>
      <value value="9502641"/>
      <value value="6983011"/>
      <value value="3139934"/>
      <value value="7407279"/>
      <value value="3440881"/>
      <value value="4705575"/>
      <value value="625587"/>
      <value value="339923"/>
      <value value="5132091"/>
      <value value="7080179"/>
      <value value="1912399"/>
      <value value="7181695"/>
      <value value="5968600"/>
      <value value="5997222"/>
      <value value="2018393"/>
      <value value="4862855"/>
      <value value="7025895"/>
      <value value="2150809"/>
      <value value="859595"/>
      <value value="8992733"/>
      <value value="7397000"/>
      <value value="2428513"/>
      <value value="6607097"/>
      <value value="7548275"/>
      <value value="8442758"/>
      <value value="1147888"/>
      <value value="1832663"/>
      <value value="1803916"/>
      <value value="4063736"/>
      <value value="5140550"/>
      <value value="9611059"/>
      <value value="875527"/>
      <value value="1625265"/>
      <value value="7838942"/>
      <value value="8261168"/>
      <value value="2759449"/>
      <value value="5771868"/>
      <value value="8035073"/>
      <value value="2738979"/>
      <value value="4521946"/>
      <value value="8495472"/>
      <value value="9228105"/>
      <value value="786346"/>
      <value value="2212873"/>
      <value value="4058832"/>
      <value value="1419616"/>
      <value value="4016686"/>
      <value value="3673139"/>
      <value value="3593572"/>
      <value value="9382611"/>
      <value value="2096894"/>
      <value value="9393863"/>
      <value value="8166876"/>
      <value value="4929272"/>
      <value value="4873859"/>
      <value value="1853053"/>
      <value value="9903814"/>
      <value value="4698802"/>
      <value value="4445299"/>
      <value value="9262332"/>
      <value value="5557732"/>
      <value value="9072776"/>
      <value value="8731048"/>
      <value value="9364917"/>
      <value value="1498520"/>
      <value value="124761"/>
      <value value="9680527"/>
      <value value="6184288"/>
      <value value="4827536"/>
      <value value="3585110"/>
      <value value="2805910"/>
      <value value="4285811"/>
      <value value="633365"/>
      <value value="7103801"/>
      <value value="2711748"/>
      <value value="7136179"/>
      <value value="9269924"/>
      <value value="2064285"/>
      <value value="2681259"/>
      <value value="4337011"/>
      <value value="1088899"/>
      <value value="2647601"/>
      <value value="1544978"/>
      <value value="1871854"/>
      <value value="7594389"/>
      <value value="5626530"/>
      <value value="9320292"/>
      <value value="6974851"/>
      <value value="7565087"/>
      <value value="9759955"/>
      <value value="7890743"/>
      <value value="2892860"/>
      <value value="9418876"/>
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
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end_day">
      <value value="76"/>
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
      <value value="0.26"/>
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
      <value value="40"/>
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
      <value value="20"/>
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
      <value value="2500000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track_r">
      <value value="true"/>
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
