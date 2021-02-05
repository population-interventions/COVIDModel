;; This version of the model has been speifically designed to estimate issues associated with Victoria's second wave of infections, beginning in early July
;; The intent of the model is for it to be used as a guide for considering differences in potential patterns of infection under various policy futures
;; As with any model, it's results should be interpreted with caution and placed alongside other evidence when interpreting results

extensions [ rngs profiler csv table ]

globals [
  anxietyFactor
  NumberInfected
  InfectionChange
  TodayInfections
  YesterdayInfections
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
  GlobalR
  CaseFatalityRate
  DeathCount
  DailyCases
  Scaled_Population
  ICUBedsRequired
  scaled_Bed_Capacity
  currentInfections
  eliminationDate
  PotentialContacts
  bluecount
  yellowcount
  redcount
  todayInfected
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

  ;; These used to be dynamic controls with conflicting variable names.
  spatial_distance
  case_isolation
  quarantine
  AsymptomaticPercentage
  contact_radius
  Track_and_Trace_Efficiency
  stage

  stageHasChanged
  stageToday
  stageYesterday

  PrimaryUpper
  SecondaryLower

  meanIDTime

  popDivisionTable ; Table of population cohort data

  ; Number of agents that are workers and essential workers respectively.
  totalWorkers
  totalEssentialWorkers
  essentialWorkerRange
  otherWorkerRange

  transmission_count
  transmission_sum
  transmission_average

  ; Vaccine phase and subphase, as well as internal index and data table.
  global_vaccinePhase
  global_vaccineSubPhase
  global_vaccineAvailible
  global_vaccineType
  global_vaccinePerDay
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

]


__includes[
  "main.nls"
  "simul.nls"
  "setup.nls"
  "packages.nls"
  "scale.nls"
  "stages.nls"
  "policy.nls"
  "trace.nls"
  "resources.nls"
  "count.nls"
  "vaccine.nls"
  "debug.nls"
]


patches-own [
  destination ;; indicator of whether this location is a place that people might gather
  lastInfectionUpdate ;; Update indicator for stale simulantCount data
  infectionList ;; List of infectivities of simulants on the patch
  lastUtilTime ;; Last tick that the patch was occupied
]
@#$#@#$#@
GRAPHICS-WINDOW
323
62
947
889
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
-30
30
-40
40
1
1
1
ticks
30.0

BUTTON
215
95
279
129
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
143
249
177
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
1400
55
1533
88
Span
Span
0
30
5.0
1
1
NIL
HORIZONTAL

PLOT
1754
115
2296
347
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
1088
1138
1288
1171
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
2662
539
2849
572
RestrictedMovement
RestrictedMovement
0
1
0.0
.01
1
NIL
HORIZONTAL

MONITOR
7
804
169
861
Deaths
Deathcount
0
1
14

SLIDER
1088
1174
1288
1207
ReInfectionRate
ReInfectionRate
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
2660
47
2792
80
Available_Resources
Available_Resources
0
4
0.0
1
1
NIL
HORIZONTAL

PLOT
2657
244
2954
389
Resource Availability
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
"default" 1.0 1 -5298144 true "" "if count resources > 0 [ plot mean [ volume ] of resources ]"

SLIDER
2658
464
2847
497
ProductionRate
ProductionRate
0
100
5.0
1
1
NIL
HORIZONTAL

MONITOR
2487
29
2642
86
# simuls
count simuls * (Total_Population / population)
0
1
14

MONITOR
2117
613
2375
658
Bed Capacity Scaled for Australia at 65,000k
count patches with [ pcolor = white ]
0
1
11

MONITOR
1392
508
1550
565
Total # Infected
numberInfected
0
1
14

PLOT
3008
327
3211
447
Fear & Action
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
"default" 1.0 1 -2674135 true "" "plot mean [ anxiety ] of simuls"

SLIDER
2660
663
2847
696
Media_Exposure
Media_Exposure
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
8
740
167
797
Mean Days infected
meanDaysInfected
2
1
14

SLIDER
1547
420
1729
453
Superspreaders
Superspreaders
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
2664
614
2849
647
Severity_of_illness
Severity_of_illness
0
100
16.0
1
1
NIL
HORIZONTAL

MONITOR
8
872
168
929
% Total Infections
numberInfected / Total_Population * 100
2
1
14

MONITOR
2247
23
2377
68
Case Fatality Rate %
caseFatalityRate * 100
2
1
11

PLOT
1162
218
1364
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
1542
57
1724
90
Proportion_People_Avoid
Proportion_People_Avoid
0
100
89.0
.5
1
NIL
HORIZONTAL

SLIDER
1542
92
1725
125
Proportion_Time_Avoid
Proportion_Time_Avoid
0
100
89.0
.5
1
NIL
HORIZONTAL

SLIDER
2658
424
2848
457
Treatment_Benefit
Treatment_Benefit
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
2662
499
2849
532
FearTrigger
FearTrigger
0
100
50.0
1
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

SWITCH
190
534
315
567
policytriggeron
policytriggeron
0
1
-1000

SLIDER
2664
579
2849
612
Initial
Initial
0
100
1.0
1
1
NIL
HORIZONTAL

MONITOR
3552
418
3707
475
Financial Reserves
mean [ reserves ] of simuls
1
1
14

PLOT
2125
363
2645
484
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
2370
473
2639
638
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
2488
574
2620
619
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
current_cases
20.0
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
189
574
315
607
Triggerday
Triggerday
0
1000
1.0
1
1
NIL
HORIZONTAL

MONITOR
963
254
1135
299
Close contacts per day
AverageContacts
2
1
11

PLOT
2117
857
2307
978
Close contacts and Mobility
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Contacts" 1.0 0 -16777216 true "" "if ticks > 0 [ plot mean [ contacts ] of simuls with [ color != black  ] ] "

PLOT
3134
458
3294
578
R0
Time
R
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"R" 1.0 0 -16777216 true "" "if count simuls with [ timenow = int ownIllnessPeriod ] > 0 [ plot MeanR ]"

PLOT
3313
375
3513
495
Population
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
"default" 1.0 0 -16777216 true "" "plot count simuls"

SLIDER
1088
1214
1290
1247
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
2788
90
3080
235
Age ranges
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

PLOT
957
740
1373
996
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
"Total Infected" 1.0 0 -13345367 true "" "plot NumberInfected "
"ICU Beds Required" 1.0 0 -16777216 true "" "plot ICUBedsRequired "

MONITOR
1394
575
1547
624
New Infections Today
DailyCases
0
1
12

PLOT
958
490
1375
610
New Infections Per Day
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if Scalephase = 1 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 10 ] \nif ScalePhase = 2 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 100 ] \nif ScalePhase = 3 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 1000 ]\nif ScalePhase = 4 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 10000 ]"
PENS
"New Cases" 1.0 1 -5298144 true "" "if scalephase = 0 [ plot count simuls with [ color = red and timenow = Case_Reporting_Delay ] ]"

SLIDER
528
902
728
935
Diffusion_Adjustment
Diffusion_Adjustment
1
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
1578
17
1722
50
Age_Isolation
Age_Isolation
0
100
0.0
1
1
NIL
HORIZONTAL

PLOT
3367
642
3527
762
Cash_Reserves
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
"Financial_Reserves" 1.0 0 -16777216 true "" "plot mean [ reserves] of simuls with [ color != black ]"

SWITCH
2657
87
2761
120
stimulus
stimulus
1
1
-1000

SWITCH
2657
129
2761
162
cruise
cruise
1
1
-1000

MONITOR
3553
484
3706
533
Stimulus
Sum [ value ] of packages * -1 * (Total_Population / Population )
0
1
12

MONITOR
3312
855
3387
912
Growth
objFunction
2
1
14

BUTTON
204
689
310
724
Stop Stimulus
ask packages [ die ] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
3552
349
3707
411
days_of_cash_reserves
30.0
1
0
Number

MONITOR
2445
668
2530
713
Mean income
mean [ income ] of simuls with [ agerange > 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
2539
668
2639
713
Mean Expenses
mean [ expenditure ] of simuls with [ agerange >= 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
8
674
147
719
Count red simuls (raw)
count simuls with [ color = red ]
0
1
11

SWITCH
1739
1089
1833
1122
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
1387
820
1585
869
Scale Phase
scalePhase
17
1
12

MONITOR
3043
585
3298
634
Negative $ Reserves
count simuls with [ shape = \"star\" ] / count simuls
2
1
12

TEXTBOX
190
658
315
681
Day 1 - Dec 21st, 2020
12
15.0
1

TEXTBOX
1395
878
1610
971
0 - 2,500 Population\n1 - 25,000 \n2 - 250,000\n3 - 2,500,000\n4 - 25,000,000
12
0.0
1

INPUTBOX
1400
94
1465
154
ppa
88.0
1
0
Number

INPUTBOX
1470
94
1534
154
pta
88.0
1
0
Number

PLOT
2338
860
2653
980
Trust in Govt
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
"default" 1.0 0 -2674135 true "" "plot mean [ personalTrust ] of simuls with [ color != black ]"

SLIDER
190
1372
393
1405
WFH_Capacity
WFH_Capacity
0
100
29.9
.1
1
NIL
HORIZONTAL

SLIDER
443
1139
583
1172
TimeLockDownOff
TimeLockDownOff
0
300
28.0
1
1
NIL
HORIZONTAL

SWITCH
1830
1310
1954
1343
lockdown_off
lockdown_off
0
1
-1000

SWITCH
1828
1224
1937
1257
freewheel
freewheel
1
1
-1000

TEXTBOX
1827
1177
2004
1215
Leave Freewheel to 'on' to manipulate policy on the fly
12
0.0
1

MONITOR
2404
43
2484
88
NIL
count simuls
17
1
11

SLIDER
190
1409
394
1442
ICU_Required
ICU_Required
0
100
1.0
1
1
NIL
HORIZONTAL

MONITOR
1812
957
1966
1006
ICU Beds Needed
ICUBedsRequired
0
1
12

PLOT
1764
825
2088
949
ICU Beds Available vs Required
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
"Required" 1.0 0 -16777216 true "" "plot ICUBedsRequired"
"Spare" 1.0 0 -5298144 true "" "plot ICU_Beds_in_Australia - ICUBedsRequired "

SLIDER
2445
812
2654
845
Mean_Individual_Income
Mean_Individual_Income
0
100000
60000.0
5000
1
NIL
HORIZONTAL

SLIDER
743
1222
918
1255
ICU_Beds_in_Australia
ICU_Beds_in_Australia
0
20000
7600.0
50
1
NIL
HORIZONTAL

SLIDER
190
1333
395
1366
Hospital_Beds_in_Australia
Hospital_Beds_in_Australia
0
200000
65000.0
5000
1
NIL
HORIZONTAL

SLIDER
2660
703
2850
736
Bed_Capacity
Bed_Capacity
0
20
9.0
1
1
NIL
HORIZONTAL

MONITOR
2577
742
2641
791
Links
count links / count simuls with [ color = red ]
0
1
12

SWITCH
1402
377
1536
410
link_switch
link_switch
0
1
-1000

INPUTBOX
2667
819
2822
879
maxv
1.0
1
0
Number

INPUTBOX
2667
889
2822
949
minv
0.0
1
0
Number

INPUTBOX
2837
957
2992
1017
phwarnings
0.8
1
0
Number

INPUTBOX
2670
959
2825
1019
saliency_of_experience
1.0
1
0
Number

INPUTBOX
2825
753
2980
813
care_attitude
0.5
1
0
Number

INPUTBOX
2829
819
2984
879
self_capacity
0.8
1
0
Number

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
1758
552
2093
675
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
1760
689
2098
811
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

PLOT
3315
510
3475
631
Compliance
NIL
NIL
80.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ owncompliancewithisolation ] of simuls"

INPUTBOX
2665
754
2820
814
initialassociationstrength
0.0
1
0
Number

MONITOR
1515
672
1580
717
Virulence
mean [ personalvirulence] of simuls
1
1
11

SLIDER
742
899
948
932
Global_Transmissability
Global_Transmissability
0
100
18.0
1
1
NIL
HORIZONTAL

MONITOR
2194
797
2250
842
A V
mean [ personalvirulence ] of simuls with [ asymptom < AsymptomaticPercentage ]
1
1
11

SLIDER
1543
260
1721
293
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
443
1177
583
1210
SeedTicks
SeedTicks
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
744
1180
919
1213
Ess_W_Risk_Reduction
Ess_W_Risk_Reduction
0
100
53.0
1
1
NIL
HORIZONTAL

SLIDER
763
1135
939
1168
App_Uptake
App_Uptake
0
100
30.0
1
1
NIL
HORIZONTAL

SWITCH
1400
419
1537
452
tracking
tracking
0
1
-1000

SLIDER
1543
299
1723
332
Mask_Wearing
Mask_Wearing
0
100
90.0
1
1
NIL
HORIZONTAL

SWITCH
1400
257
1535
290
schoolsPolicy
schoolsPolicy
1
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

SWITCH
1487
1158
1621
1191
AssignAppEss
AssignAppEss
0
1
-1000

SLIDER
935
1219
1063
1252
eWAppUptake
eWAppUptake
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
960
163
1123
196
TTIncrease
TTIncrease
0
5
2.0
.01
1
NIL
HORIZONTAL

MONITOR
2445
754
2561
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
1545
130
1723
163
SchoolPolicyActive
SchoolPolicyActive
1
1
-1000

SLIDER
945
1135
1077
1168
SchoolReturnDate
SchoolReturnDate
0
100
3.0
1
1
NIL
HORIZONTAL

SWITCH
1400
335
1534
368
MaskPolicy
MaskPolicy
0
1
-1000

SLIDER
1547
339
1727
372
ResidualCautionPPA
ResidualCautionPPA
0
100
81.0
1
1
NIL
HORIZONTAL

SLIDER
1547
380
1726
413
ResidualCautionPTA
ResidualCautionPTA
0
100
81.0
1
1
NIL
HORIZONTAL

SLIDER
2832
889
2988
922
Case_Reporting_Delay
Case_Reporting_Delay
0
20
6.0
1
1
NIL
HORIZONTAL

PLOT
3038
797
3293
947
R and Compliance Distributions 
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
"default" 1.0 1 -16777216 true "" "histogram [ R ] of simuls with [ color != 85 ] "
"Compliance" 1.0 0 -2674135 true "" "histogram [ ownCompliancewithIsolation * 10 ] of simuls "

MONITOR
3035
663
3093
708
R Sum
sum [ r ] of simuls with [ color != 85 ]
1
1
11

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
3092
663
3142
708
=1
sum [ r ] of simuls with [ color != 85  and R = 1]
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
3110
242
3283
275
Visit_Frequency
Visit_Frequency
0
6
6.0
1
1
NIL
HORIZONTAL

SLIDER
3112
280
3285
313
Visit_Radius
Visit_Radius
0
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
3310
803
3368
848
%>3
count simuls with [ color != 85 and R > 2] / count simuls with [ color != 85 and R > 0 ] * 100
2
1
11

MONITOR
3377
803
3435
848
% R
sum [ R ] of simuls with [ color != 85 and R > 2] / sum [ R ] of simuls with [ color != 85 and R > 0 ] * 100
2
1
11

SLIDER
745
942
947
975
Asymptomatic_Trans
Asymptomatic_Trans
0
1
0.35
.01
1
NIL
HORIZONTAL

SWITCH
443
1217
588
1250
OS_Import_Switch
OS_Import_Switch
0
1
-1000

SLIDER
195
1248
397
1281
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
2126
488
2198
533
OS %
( count simuls with [  imported = 1 ] / count simuls with [ color != 85 ]) * 100
2
1
11

SLIDER
1543
222
1720
255
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
1388
669
1496
714
NIL
currentinfections
17
1
11

MONITOR
2198
498
2273
543
Illness time
mean [ timenow ] of simuls with [ color = red ]
1
1
11

MONITOR
2272
792
2377
853
ICU Beds
ICUBedsRequired
0
1
15

SWITCH
1400
297
1534
330
Complacency
Complacency
0
1
-1000

CHOOSER
1502
945
1595
990
InitialScale
InitialScale
0 1 2 3 4
0

PLOT
959
360
1374
484
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

INPUTBOX
2302
98
2382
159
zerotoone
1.0
1
0
Number

INPUTBOX
2302
160
2382
221
onetotwo
35.0
1
0
Number

INPUTBOX
2300
224
2383
284
twotothree
56.0
1
0
Number

INPUTBOX
2300
284
2382
345
threetofour
210.0
1
0
Number

SWITCH
1828
1265
1940
1298
SelfGovern
SelfGovern
0
1
-1000

PLOT
957
615
1374
735
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
1388
769
1503
814
Cases in period 7
casesinperiod7
0
1
11

INPUTBOX
2388
98
2470
159
JudgeDay1
2.0
1
0
Number

INPUTBOX
2389
167
2472
228
JudgeDay2
2.0
1
0
Number

INPUTBOX
2390
228
2472
289
JudgeDay3
2.0
1
0
Number

INPUTBOX
2390
292
2472
353
JudgeDay4
2.0
1
0
Number

MONITOR
2313
684
2423
729
Policy Reset Date
ResetDate
0
1
11

INPUTBOX
2864
602
3020
663
UpperStudentAge
18.0
1
0
Number

INPUTBOX
2865
673
3021
734
LowerStudentAge
4.0
1
0
Number

PLOT
3399
83
3579
233
Objective Function
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
"default" 1.0 0 -2674135 true "" "plot Objfunction"

SLIDER
2208
1269
2381
1302
Outside
Outside
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
2208
1307
2381
1340
outsideRisk
outsideRisk
0
100
37.0
1
1
NIL
HORIZONTAL

MONITOR
2200
1227
2283
1272
Green space
count patches with [ pcolor = green ]
0
1
11

INPUTBOX
2554
99
2627
160
onetozero
0.0
1
0
Number

INPUTBOX
2558
160
2630
221
twotoone
1.0
1
0
Number

INPUTBOX
2557
225
2627
286
threetotwo
35.0
1
0
Number

INPUTBOX
2557
285
2629
346
fourtothree
105.0
1
0
Number

MONITOR
207
848
289
893
Yellow (raw)
count simuls with [ color = yellow ]
0
1
11

INPUTBOX
2478
102
2548
162
JudgeDay1_d
1.0
1
0
Number

INPUTBOX
2479
160
2553
220
Judgeday2_d
1.0
1
0
Number

INPUTBOX
2478
225
2555
285
Judgeday3_d
1.0
1
0
Number

INPUTBOX
2478
289
2553
349
Judgeday4_d
1.0
1
0
Number

SLIDER
530
942
728
975
Undetected_Proportion
Undetected_Proportion
0
100
29.0
1
1
NIL
HORIZONTAL

MONITOR
8
619
123
664
Undetected Cases
count simuls with [ color = red and undetectedFlag = 1 ]
0
1
11

SLIDER
2062
67
2235
100
Household_Attack
Household_Attack
0
100
30.0
1
1
NIL
HORIZONTAL

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
2288
502
2353
547
Students
count simuls with [ studentFlag = 1 ]
0
1
11

SLIDER
328
940
517
973
IncursionRate
IncursionRate
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
3008
14
3123
59
Last Decision Date
DecisionDate
0
1
11

SWITCH
1630
1268
1734
1301
Isolate
Isolate
0
1
-1000

SLIDER
324
900
512
933
Mask_Efficacy_Mult
Mask_Efficacy_Mult
0
3
2.45
.01
1
NIL
HORIZONTAL

SWITCH
1628
1310
1781
1343
Vaccine_Available
Vaccine_Available
0
1
-1000

CHOOSER
1604
823
1743
868
BaseStage
BaseStage
0 1 2 3 4
1

MONITOR
8
568
97
613
Mean ID Time
meanIDTime
1
1
11

SLIDER
2799
45
2972
78
GoldStandard
GoldStandard
0
100
100.0
1
1
NIL
HORIZONTAL

CHOOSER
1605
878
1744
923
MaxStage
MaxStage
0 1 2 3 4
4

MONITOR
1160
13
1250
58
Vaccinated %
( count simuls with [ shape = \"person\" ] / 2500 )* 100
2
1
11

SLIDER
189
612
315
645
RAND_SEED
RAND_SEED
0
1000000
523256.0
1
1
NIL
HORIZONTAL

MONITOR
1259
13
1349
58
Vaccinated
count simuls with [ shape = \"person\" ]
17
1
11

PLOT
1160
67
1360
205
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

SLIDER
7
188
182
221
param_transmit_scale
param_transmit_scale
1
1.5
1.5
0.25
1
NIL
HORIZONTAL

TEXTBOX
12
402
180
469
Vaccine rollout and vaccine used per phase set in vaccine.csv.
14
0.0
1

SLIDER
8
228
180
261
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
8
270
182
303
param_vac2_morb_eff
param_vac2_morb_eff
60
80
60.0
10
1
NIL
HORIZONTAL

SLIDER
8
312
177
345
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
7
355
180
388
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
9
467
181
500
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
1503
898
1591
943
NIL
contact_radius
17
1
11

MONITOR
1400
157
1537
202
NIL
spatial_distance
17
1
11

MONITOR
1402
207
1536
252
NIL
case_isolation
17
1
11

MONITOR
1543
170
1720
215
NIL
quarantine
17
1
11

MONITOR
1324
1165
1482
1210
NIL
AsymptomaticPercentage
17
1
11

MONITOR
962
202
1134
247
NIL
Track_and_Trace_Efficiency
17
1
11

MONITOR
960
307
1017
352
NIL
stage
17
1
11

MONITOR
1613
569
1748
614
NIL
transmission_average
17
1
11

MONITOR
1627
515
1747
560
NIL
transmission_count
17
1
11

PLOT
1758
363
2101
535
Potential transmission interactions per day
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
"default" 1.0 0 -16777216 true "" "plot transmission_count"

TEXTBOX
1412
27
1536
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
houseCases
80.0
1
0
Number

CHOOSER
10
508
183
553
param_policy
param_policy
"AgggressElim" "ModerateElim" "TightSupress" "LooseSupress" "None"
1

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
  <experiment name="Australia" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="132"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wuhan" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set current_cases current_cases + random-normal 20 10
set AsymptomaticPercentage AsymptomaticPercentage + random 10 - random 10
set PPA random 100
set PTA random 100</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>StudentInfections</metric>
    <metric>EWInfections</metric>
    <metric>count simuls with [ Asymptomaticflag = 1 ]</metric>
    <metric>PPA</metric>
    <metric>PTA</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="129"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="11000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="53"/>
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NZ new" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="5000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="39"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Australia Asymptomatic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="132"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wuhan new" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set current_cases current_cases + random-normal 20 10
set AsymptomaticPercentage AsymptomaticPercentage + random 10 - random 10
set PPA random 100
set PTA random 100</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>StudentInfections</metric>
    <metric>EWInfections</metric>
    <metric>count simuls with [ Asymptomaticflag = 1 ]</metric>
    <metric>PPA</metric>
    <metric>PTA</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="129"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="11000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="53"/>
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria HE" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>lasttransday</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="341"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="80"/>
      <value value="70"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria LE Masks Decay Test" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>lasttransday</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="70"/>
      <value value="50"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria LE Grattan 1" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomatic asymptomatic + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria new MJA" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 2</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R experiment" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count simuls with [ color = red ] = 0</exitCondition>
    <metric>numberInfected / Total_Population * 100</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="2301"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="181"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="4.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MJA stage 4 no complacency" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>mean [ contacts ] of simuls</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MJA stage 3 no complacency" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="150"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="0"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Balanced" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="941"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Min Cases" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="291"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="841"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1801"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Max Mobility" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="271"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="701"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="4101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Elimination Aggressive" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Elimination Moderate" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Multiple JN" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 28_8" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
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
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="28"/>
      <value value="42"/>
      <value value="56"/>
      <value value="70"/>
      <value value="84"/>
      <value value="98"/>
      <value value="112"/>
      <value value="126"/>
      <value value="140"/>
      <value value="210"/>
      <value value="280"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 31_8 New" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
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
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="28"/>
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="210"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tight Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="31.9786782754768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.26642146168603675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="31.9786782754768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.26642146168603675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 31_8 Testing for seedticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="35"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
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
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 1_9 Evening Testing" repetitions="250" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="303"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="42"/>
      <value value="70"/>
      <value value="98"/>
      <value value="140"/>
      <value value="210"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 1_9 Evening Testing High" repetitions="150" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="120"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Final Schools back run" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="120"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tony Aggressive" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tony Moderate" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tight Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="224"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="896"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="448"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="224"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="4480"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1120"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Balanced Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="100000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Case Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Mobility Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression Variation Test" repetitions="300" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="5250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="7500000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="2625"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1312"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggressive Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Unmitigated Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>ObjFunction</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jan Tests Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set stage BaseStage</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <metric>meanIDTime</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
      <value value="70"/>
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Available">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VEffectiveness">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Rate">
      <value value="2.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Bumble Along" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
;;set App_uptake App_Uptake + random-normal 0 4
set stage BaseStage</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <metric>meanIDTime</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GoldStandard">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaxStage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Available">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VEffectiveness">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Rate">
      <value value="2.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set stage BaseStage</setup>
    <go>go</go>
    <timeLimit steps="2"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <metric>meanIDTime</metric>
    <enumeratedValueSet variable="RAND_SEED">
      <value value="1234"/>
      <value value="1234"/>
      <value value="8888"/>
      <value value="5555"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Available">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Efficacy">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Rate">
      <value value="2.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
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
