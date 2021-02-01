;; This version of the model has been speifically designed to estimate issues associated with Victoria's second wave of infections, beginning in early July
;; The intent of the model is for it to be used as a guide for considering differences in potential patterns of infection under various policy futures
;; As with any model, it's results should be interpreted with caution and placed alongside other evidence when interpreting results

extensions [ rngs profiler csv ]

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

  stageHasChanged
  stageToday
  stageYesterday

  PrimaryUpper
  SecondaryLower

  meanIDTime


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
]


patches-own [
  utilisation ;; indicator of whether any people are located on that patch of the environment or not
  destination ;; indicator of whether this location is a place that people might gather
]

to avoidICUs
  ;; makes sure that simulswho have not been sent to hospital stay outside
  if [ pcolor ] of patch-here = white and InICU = 0 [
    move-to min-one-of patches with [ pcolor = black ] [ distance myself ]
  ]
end


to avoid
  ;; these are the circustances under which people will interact
  ask simuls [
    ;; so, if the social distancing policies are on and you are distancing at this time and you are not part of an age-isolated
    ;; group and you are not an essentialworker, then if there is anyone near you, move away if you can.
    (ifelse Spatial_Distance = true and (Proportion_People_Avoid + random-normal 0 3) > random 100
        and (Proportion_Time_Avoid + random-normal 0 3) > random 100 and AgeRange > Age_Isolation and EssentialWorkerFlag = 0
    [
      if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself ] [
        if any? neighbors with [ utilisation = 0 ] [
          move-to one-of neighbors with [ utilisation = 0 ]
        ]
      ]
    ]
    ;; elseif
    ;; if you are an essential worker, you can only reduce your
    ;; contacts when you are not at work assuming 8 hours work, 8 hours rest, 8 hours recreation - rest doesn't count for anyone, hence it is
    ;; set at 50 on the input slider. People don't isolate from others in their household unit
    Spatial_Distance = true and (Proportion_People_Avoid + random-normal 0 3) > random 100 and (Proportion_Time_Avoid + random-normal 0 3) > random 100
        and AgeRange > Age_Isolation and EssentialWorkerFlag = 1
    [
      if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself ] [
        if any? neighbors with [ utilisation = 0 ] and Ess_W_Risk_Reduction > random 100 [
          move-to one-of neighbors with [ utilisation = 0 ]
        ]
      ]
    ]
    [
      ;; otherwise just move wherever you like
      set heading heading + contact_Radius fd random pace
      avoidICUs
      move-to patch-here
    ])
  ]

  if policyTriggerOn = true and freewheel = false and schoolsPolicy = true and ticks >= triggerday + SchoolReturnDate [
    ask simuls with [ studentFlag = 1 ] [
      ;; same thing but specifically targets the movement of students if the schools policy is turned on - that is
      ;; if students are expected to return to school
      ;; schoolspolicy = true means 'go to school = true
      ifelse Spatial_Distance = true and Proportion_People_Avoid + random-normal 0 3 > random 100
          and Proportion_Time_Avoid + random-normal 0 3 > random 100 and AgeRange > Age_Isolation
      [
        if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself or studentFlag != 1 ] [
          ;; students don't isolate from each other or their household unit
          if any? neighbors with [ utilisation = 0 ] and Ess_W_Risk_Reduction > random 100 [
            move-to one-of neighbors with [ utilisation = 0 ]
          ]
        ]
      ]
      ;; if you are a student, you avoid everyone you can except for essential workers (i.e., teachers), other students
      ;; and people from your own household
      [
        move-to one-of simuls with [ essentialworkerflag = 1 or householdUnit = [ householdUnit ] of myself or studentFlag = 1 ]
      ]
    ]
  ]
end


to finished
  if freewheel = true [
    ;; stops the model if the following criteria are met - no more infected people in the simulation and it has run for at least 10 days
    if ticks > 100 and count simuls with [ color = red ] = 0 [
      stop
    ]
  ]
end


to superSpread
  if count simuls with [ color = red and tracked = 0 ] > 1 and Case_Isolation = false [
    if Superspreaders > random 100 [
      ;; asks some people who are infected and not tracked to move to random new areas,
      ;;potentially among susceptible people if travel restrictions are not current
      ask n-of int (count simuls with [ color = red and tracked = 0 ] / Diffusion_Adjustment ) simuls with [ color = red and tracked = 0 ] [
        fd world-width / 2
      ]

      ;; same as above but for recovered people to take into account immunity in the population
      if count simuls with [ color = yellow ] >= Diffusion_Adjustment [
        ask n-of int ( count simuls with [ color = yellow ] / Diffusion_Adjustment ) Simuls with [ color = yellow ] [
          fd world-width / 2
        ]
      ]
    ]
  ]


  if count simuls with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] > Diffusion_Adjustment and Case_Isolation = true [
    if Superspreaders > random 100 [
      ;; only moves people who don't know they are sick yet
      ask n-of int (count simuls with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] / Diffusion_Adjustment ) simuls
          with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] [
        fd world-width / 2
      ]

      ;; this ensures that people with immunity also move to new areas, not just infected people
      if count simuls with [ color = yellow ] >= 1 [
        ask n-of int (count simuls with [ color = yellow ] / Diffusion_Adjustment) simuls with [ color = yellow ] [
          fd world-width / 2
        ]
      ]
    ]
  ]
end


;;;*******************ANXIETY******************::::::::::::::::::


to Globalanxiety
  ;; levels of global anxiety are tied to knowledge of dead and infected
  ;; people multiplied by media exposure of dead and infected people
  let anxiouscohort (count simuls with [ color = red ] + count simuls with [ color = black ] - count simuls with [ color = yellow ] ) / Total_Population

  if scalephase = 0 [
    set anxietyFactor anxiouscohort * media_Exposure
  ]
  if scalephase = 1 [
    set anxietyFactor anxiouscohort * 10 * media_Exposure
  ]
  if scalephase = 2 [
    set anxietyFactor anxiouscohort * 100 * media_Exposure
  ]
  if scalephase = 3 [
    set anxietyFactor anxiouscohort * 1000 * media_Exposure
  ]
  if scalephase = 4 [
    set anxietyFactor anxiouscohort * 10000 * media_Exposure
  ]
end

to GlobalTreat
  ;; send people to quarantine if they have been identified
  let eligiblesimuls simuls with [ color = red and inICU = 0 and ownIncubationPeriod >= Incubation_Period and asymptom >= AsymptomaticPercentage and tracked = 1 ]

  ;; only symptomatic cases are identified
  if (count simuls with [ InICU = 1 ]) < (count patches with [ pcolor = white ]) and Quarantine = true and any? eligiblesimuls [
    ask n-of ( count eligiblesimuls * Track_and_Trace_Efficiency ) eligiblesimuls [
      move-to one-of patches with [ pcolor = white ]
      set inICU 1
    ]
  ]
end

to TriggerActionIsolation
  ;; sets the date for social isolation and case isolation
  if PolicyTriggerOn = true and Freewheel = false [
    if ticks >= Triggerday and Freewheel = false [
      set Spatial_Distance true
      set Case_Isolation true
      set Quarantine true
    ]
  ]
end

to checkutilisation
  ;; records which patches are being occupied by simuls
  ifelse any? simuls-here
  [
    set utilisation 1
  ]
  [
    set utilisation 0
  ]
end


to forwardTime
  ;; counts days per tick, likely redundant at present as days are not used for anything right now.
  set days days + 1
end

To Unlock
  ;; reverses the initiation of social distancing and isolation policies over time. Recognises that the policies are interpreted
  ;; and adherence is not binary. Adherence to policies is associated with a negative exponential curve linked to the current day
  ;; and the number of days until the policies are due to be relaxed at which point they are relaxed fully.

  if Complacency = true and PolicyTriggerOn = true and LockDown_Off = true and ticks >= Triggerday
      and int Proportion_People_Avoid > ResidualCautionPPA [
    set PPA (PPA - 1 )
    set Proportion_People_Avoid PPA
  ]

  if Complacency = true and PolicyTriggerOn = true and LockDown_Off = true and ticks >= Triggerday
      and int Proportion_Time_Avoid > ResidualCautionPTA [
    set PTA (PTA - 1 )
    set Proportion_Time_Avoid PTA
  ]
end

;;;;;;;;;;;;*********END OF TTI FUNCTIONS******* ;;;;;;;;;;;;;



to OSCase
  if policytriggeron = true and count simuls with [ color = red and imported = 0 ] > 1 [
    let totallocal count simuls with [ color != cyan and imported = 0 ]
    let totalimported count simuls with [ imported = 1 ]
    let ratio ( totalimported / (totallocal + totalimported) )

    ;; contributes additional cases as a result of OS imports prior to lockdown
    if ticks <= triggerday and OS_Import_Switch = true and ratio < OS_Import_Proportion [
      ask n-of ( count simuls with [ color = red ] * .10 ) simuls with [ color = cyan ] [
        set color red
        set timenow int ownIncubationPeriod - random-normal 1 .5
        set Essentialworker random 100
        set imported 1
      ]
    ]

    ;; creates steady stream of OS cases at beginning of pandemic
    if ticks <= triggerday and OS_Import_Switch = true [
      ask n-of 1 simuls with [ color = cyan ] [
        set color red
        set timenow int ownIncubationPeriod - random-normal 1 .5
        set Essentialworker random 100
        set imported 1
      ]
    ]

    ;; contributes additional cases as a result of OS imports after lockdown
    if ticks > triggerday and OS_Import_Switch = true and ratio < OS_Import_Post_Proportion [
      ask n-of ( count simuls with [ color = red ] * .05 ) simuls with [ color = cyan ] [
        set color red
        set timenow int ownIncubationPeriod - random-normal 1 .5
        set Essentialworker random 100
        set imported 1
        set tracked 1
      ]
    ]
  ]
end

to stopfade
  ;; prevents cases from dying out in the eraly stage of the trials when few numbers exist
  if freewheel != true [
    if ticks < Triggerday and count simuls with [ color = red ] < 3 [
      ask n-of 1 simuls with [ color = cyan ] [
        set color red
        set timenow int ownIncubationPeriod - 1
        set Essentialworker random 100
      ]
    ]
  ]
end

to-report nonesspercentage
  if count simuls with [ essentialworkerflag != 1 and color != cyan ] > 0 [
    report (count simuls with [ essentialworkerflag != 1 and color != cyan] ) / (count simuls with [ essentialWorkerFlag != 1 ])
  ]
end

to linearbehdecrease
  if complacency = true [
    if ticks > triggerday and ppa > ResidualCautionppa [
      set ppa (ppa - 1)
      set pta ( pta - 1)
    ]
  ]
end

to updateoutside
  ;; controls the amount of time that interactions happen outside
  if count patches with [ pcolor = green ] < ( Outside * (count patches) ) [
    ask n-of random 10 patches with [ pcolor = black ] [
      set pcolor green
    ]
  ]
  if count patches with [ pcolor = green ] > ( Outside * (count patches) ) [
    ask n-of random 10 patches with [ pcolor = green ] [
      set pcolor black
    ]
  ]
end

to incursion
  ;; randomly asks someone to become infected
  if ticks > 0 and currentinfections = 0 and IncursionRate > random-float 100 [
    ask one-of simuls with [ color = cyan ] [
      set color red
    ]
  ]
end


;;*******************************************************************************************************************************
;;** Buttons **
;;*******************************************************************************************************************************


to go
  ;; these funtions get called each time-step
  ask simuls [
    ;; Move either outside or back to home, then potentially catch the infection from whoever is there. Large function.
    simul_move
    ;; if you are not dead at the end of your illness period, then you become recovered and turn yellow. Don't need hospital resources anymore.
    simul_recover
    ;; Increment illness time and possibly lose 'health' due to it. It is unclear what health is for.
    simul_settime
    ;; Possibly die if infected.
    simul_death
    ;; Move everyone home based on their chance of being compliant with isolation. It is weird that this happens after simul_move, in which people
    ;; who are out and about can infect each other.
    simul_isolation
    ;; Recovered people can randomly become infected again.
    simul_reinfect
    ;; Give people anxiety based on global factors.
    simul_createanxiety
    ;; Pick up resources, which seems to reduce anxiety?
    simul_gatherreseources
    ;; Infected people with inICU = 1 are moved to a white patch (hospital?)
    simul_treat
    ;; Take the rolling average of contacts over the past seven days, only for non-infected people.
    simul_Countcontacts
    ;; Untracked people have their speed set to the current recommended speed, based on policy.
    simul_respeed
    ;; Set infected people to always require ICU after their incubation period???
    simul_checkICU
    ;; Randomly start tracking infected people based on track_and_trace_efficiency. Note that simul_traceme can also be called upon being infected
    ;; so track_and_trace_efficiency is not exactly the tracking rate per timestep.
    simul_traceme
    ;; Set EssentialWorkerFlag based on proportion of population that is an essential worker (uses Essential_Workers (0-100) policy param)
    simul_EssentialWorkerID
    ;; Randomly set app-people to hunted, and set hunted people to tracked.
    simul_hunt
    ;; enables people to access the support packages (???)
    simul_AccessPackage
    ;; Set a proprtion of people to wear masks when not home  (uses mask_Wearing (0-100) policy param)
    simul_checkMask
    ;; creates a triangular distribution of virulence that peaks at the end of the incubation period
    simul_updatepersonalvirulence
    ;; Set 1/7th of people who are near a destination to move to that destination.
    simul_visitDestination
    ;; If I am succeptible and a household member is tracked, move home and set pace to 0, set isolated=1. Also track isolated=1 infected people.
    simul_HHContactsIso
    ;; Randomly vaccinate people according to uptake and stage.
    simul_vaccinate_me
  ]
  ; *current excluded functions for reducing processing resources**
  ask medresources [
    allocatebed
  ]
  ask resources [
    deplete
    replenish
    resize
    spin
  ]
  ask packages [
    absorbshock
    movepackages
  ]

  ;; Set a list of policy parameters (span (speed), tracking, mask_wearning etc..) based on current stage and stage reset timers
  setupstages
  ;; stops the model if the following criteria are met - no more infected people in the simulation and it has run for at least 10 days, only if freewheel = true.
  finished
  ;CruiseShip
  ;; Send people to ICU if they have been identified
  GlobalTreat
  ;; Set anxiety factor based on some infected/dead/recovered count, multiplied by media_Exposure
  Globalanxiety
  ;; Randomly move infected people  who are untracked or unaware they are sick to new areas, based on the Superspreaders parameter, set in Stages.
  SuperSpread
  ;; set numberinfected cumulativeInfected (???)
  CountInfected
  ;; Calculate proportional change in real infection count. Updates InfectionChange, TodayInfections and YesterdayInfections
  CalculateDailyGrowth
  ;; Enable distancing, isolation and quarantine based on triggers
  TriggerActionIsolation
  ;; Mouse click does something interactive
  DeployStimulus
  ;setInitialReserves
  ;; Set AverageContacts. Doesn't appear to do anything?
  CalculateAverageContacts
  ;; Check whether to scale up, which occurs when 10% of the agents are infected.
  ScaleUp
  ;; set days days + 1
  ForwardTime
  ;; Reverses the initiation of social distancing and isolation policies over time.
  Unlock

  ;; Calculate various metrics, which may be used for policy or may just be output.
  setCaseFatalityRate
  countDailyCases
  calculatePopulationScale
  calculateICUBedsRequired
  calculateScaledBedCapacity
  calculateCurrentInfections
  calculateEliminationDate

  ;; Update tracking links in covid app or similar tracing functions
  assesslinks
  ;; PotentialContacts metric
  calculatePotentialContacts

  ;; Cache number of infected (red) suceptible (blue (actually cyan)) and recovered (yellow) agents
  countRed
  countBlue
  countYellow

  ;; Randomly remove the excess agents when they exceed the fixed agent population (eg 2500), provided they are not infected or dead.
  scaledownhatch

  ;; Set cumulativeInfected, not yesterdayInfected
  calculateYesterdayInfected
  ;; Set todayInfected from dailycases
  calculateTodayInfected
  ;; calculates scaledPopulation for working with smaller environments
  calculateScaledPopulation
  ;; Average R of infected simulants.
  calculateMeanR

  ;; Randomly set some simulants to be infected, to simulate overseas cases. They have imported = 1.
  OSCase
  ;; Spontaneously generate a case if ticks < Triggerday and there are fewer than three cases.
  stopFade
  ;seedCases

  ;; A massive function that randomly moves agents away to neighbouring patches if Spatial_Distance = True, otherwise avoid ICU. Also
  ;; makes students avoid some people but not others if schoolsPolicy = true.
  avoid

  ;; ensures that policies are enacted if their master switches are set to true at the time of the policy switch turning on (?)
  turnOnTracking
  ;; counts infections among Essential workers
  countEWInfections
  ;; counts infections among school students
  countSchoolInfections
  ;; stops the model if the following criteria are met - no more infected people in the simulation and it has run for at least 10 days
  finished
  ;; set meanDaysInfected
  calculateMeanDaysInfected
  ;profilerstop

  ;; set track_and_trace_efficiency based on the number of recent cases.
  traceadjust
  ;; Reduce ppa and pta usage if complacency = True.
  linearbehdecrease
  ;; Set lockdown stage and easing date, bases mostly on casesinperiod7
  CovidPolicyTriggers
  ;; Set casesinperiod7, which is only detected cases. Also sets casesinperiod14 and casesinperiod28.
  calculateCasesInLastPeriod
  ;calculateCashPosition

  ;; Set objFunction. Doesn't appear to do anything.
  calculateObjfunction
  ;; controls the amount of time that interactions happen outside
  updateoutside
  ;updatestudentStatus

  ;; Randomly turn suceptible agents into infected ones. Percentage chance = IncursionRate.
  incursion
  ;; Average "days into infection the person is identified as a case" of suceptible agents.
  CalculateMeanIDTime
  ;; Set Vaccine_Efficacy based on Vaccine_Type
  VaccineBrand

  ask patches [
    checkutilisation
  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
316
123
934
942
-1
-1
10.0
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
0
0
1
ticks
30.0

BUTTON
205
176
269
210
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
169
220
233
254
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
175
348
293
382
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
175
396
293
430
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

SWITCH
699
135
899
168
spatial_distance
spatial_distance
0
1
-1000

SLIDER
165
270
305
303
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
165
306
306
339
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
1396
122
1918
387
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
699
428
899
461
Illness_period
Illness_period
0
25
20.7
.1
1
NIL
HORIZONTAL

SWITCH
700
172
898
205
case_isolation
case_isolation
0
1
-1000

BUTTON
228
220
292
254
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
1936
569
2123
602
RestrictedMovement
RestrictedMovement
0
1
0.01
.01
1
NIL
HORIZONTAL

MONITOR
338
876
493
933
Deaths
Deathcount
0
1
14

MONITOR
963
133
1053
178
Time Count
ticks
0
1
11

SLIDER
699
465
899
498
ReInfectionRate
ReInfectionRate
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
699
316
899
349
quarantine
quarantine
0
1
-1000

SLIDER
138
713
327
746
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
1929
272
2226
417
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
1933
493
2122
526
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
965
310
1120
367
# simuls
count simuls * (Total_Population / population)
0
1
14

MONITOR
1400
934
1660
979
Bed Capacity Scaled for Australia at 65,000k
count patches with [ pcolor = white ]
0
1
11

MONITOR
335
685
493
742
Total # Infected
numberInfected
0
1
14

SLIDER
700
282
899
315
Track_and_Trace_Efficiency
Track_and_Trace_Efficiency
0
1
0.25
.05
1
NIL
HORIZONTAL

PLOT
1155
343
1360
493
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
1938
686
2125
719
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
335
748
494
805
Mean Days infected
meanDaysInfected
2
1
14

SLIDER
700
542
900
575
Superspreaders
Superspreaders
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
1938
646
2123
679
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
338
815
491
872
% Total Infections
numberInfected / Total_Population * 100
2
1
14

MONITOR
1153
125
1283
170
Case Fatality Rate %
caseFatalityRate * 100
2
1
11

PLOT
1153
185
1353
335
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
700
209
898
242
Proportion_People_Avoid
Proportion_People_Avoid
0
100
15.0
.5
1
NIL
HORIZONTAL

SLIDER
699
245
898
278
Proportion_Time_Avoid
Proportion_Time_Avoid
0
100
15.0
.5
1
NIL
HORIZONTAL

SLIDER
1933
453
2123
486
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
1936
529
2123
562
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
955
630
1014
675
R0
mean [ R ] of simuls with [ color = red and timenow = int Illness_Period ]
2
1
11

SWITCH
160
575
304
608
policytriggeron
policytriggeron
0
1
-1000

SLIDER
1936
609
2121
642
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
963
249
1118
306
Financial Reserves
mean [ reserves ] of simuls
1
1
14

PLOT
1398
390
1918
511
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
1398
619
1918
769
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

SLIDER
699
355
898
388
Compliance_with_Isolation
Compliance_with_Isolation
0
100
95.0
1
1
NIL
HORIZONTAL

MONITOR
1742
639
1874
684
Infection Growth %
infectionchange
2
1
11

INPUTBOX
158
443
314
504
current_cases
1.0
1
0
Number

INPUTBOX
158
508
314
569
total_population
2.5E7
1
0
Number

SLIDER
137
615
311
648
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
965
425
1120
470
Close contacts per day
AverageContacts
2
1
11

PLOT
965
506
1155
627
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
951
678
1161
838
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
1160
503
1360
624
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
699
505
901
538
Incubation_Period
Incubation_Period
0
10
5.1
.1
1
NIL
HORIZONTAL

PLOT
1931
123
2223
268
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
952
842
1368
1098
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
335
626
488
675
New Infections Today
DailyCases
0
1
12

PLOT
330
943
632
1098
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
700
578
900
611
Diffusion_Adjustment
Diffusion_Adjustment
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
700
615
899
648
Age_Isolation
Age_Isolation
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
702
652
901
685
Contact_Radius
Contact_Radius
0
180
0.0
1
1
NIL
HORIZONTAL

PLOT
1400
772
1925
925
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
173
753
277
786
stimulus
stimulus
1
1
-1000

SWITCH
173
796
277
829
cruise
cruise
0
1
-1000

MONITOR
963
370
1116
419
Stimulus
Sum [ value ] of packages * -1 * (Total_Population / Population )
0
1
12

MONITOR
1439
850
1514
907
Growth
objFunction
2
1
14

BUTTON
170
843
276
878
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
963
183
1118
245
days_of_cash_reserves
30.0
1
0
Number

MONITOR
1400
983
1485
1028
Mean income
mean [ income ] of simuls with [ agerange > 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
1493
983
1593
1028
Mean Expenses
mean [ expenditure ] of simuls with [ agerange >= 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
52
885
191
930
Count red simuls (raw)
count simuls with [ color = red ]
0
1
11

SWITCH
178
952
283
985
scale
scale
0
1
-1000

MONITOR
1059
133
1117
178
NIL
Days
17
1
11

MONITOR
1160
687
1358
736
Scale Phase
scalePhase
17
1
12

MONITOR
1669
929
1924
978
Negative $ Reserves
count simuls with [ shape = \"star\" ] / count simuls
2
1
12

TEXTBOX
163
692
336
714
Day 1 - Dec 21st, 2020
12
15.0
1

TEXTBOX
1164
744
1379
837
0 - 2,500 Population\n1 - 25,000 \n2 - 250,000\n3 - 2,500,000\n4 - 25,000,000
12
0.0
1

INPUTBOX
530
216
609
284
ppa
15.0
1
0
Number

INPUTBOX
615
216
700
285
pta
15.0
1
0
Number

TEXTBOX
346
210
522
296
Manually enter the proportion of people who avoid (PPA) and time avoided (PTA) here when using the policy trigger switch
12
0.0
0

PLOT
1609
984
1924
1104
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
700
858
903
891
WFH_Capacity
WFH_Capacity
0
100
30.0
.1
1
NIL
HORIZONTAL

SLIDER
140
1035
314
1068
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
163
993
292
1026
lockdown_off
lockdown_off
0
1
-1000

SWITCH
189
130
298
163
freewheel
freewheel
1
1
-1000

TEXTBOX
143
80
358
118
Leave Freewheel to 'on' to manipulate policy on the fly
12
0.0
1

MONITOR
1292
128
1372
173
NIL
count simuls
17
1
11

SLIDER
700
898
904
931
ICU_Required
ICU_Required
0
100
5.0
1
1
NIL
HORIZONTAL

MONITOR
335
570
489
619
ICU Beds Needed
ICUBedsRequired
0
1
12

PLOT
630
942
949
1097
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
1027
635
1236
668
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
335
532
510
565
ICU_Beds_in_Australia
ICU_Beds_in_Australia
0
20000
7000.0
50
1
NIL
HORIZONTAL

SLIDER
700
819
905
852
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
1938
727
2128
760
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
1530
1052
1594
1101
Links
count links / count simuls with [ color = red ]
0
1
12

SWITCH
1400
1033
1514
1066
link_switch
link_switch
0
1
-1000

INPUTBOX
1945
842
2100
902
maxv
1.0
1
0
Number

INPUTBOX
1945
912
2100
972
minv
0.0
1
0
Number

INPUTBOX
1947
977
2102
1037
phwarnings
0.8
1
0
Number

INPUTBOX
1949
1044
2104
1104
saliency_of_experience
1.0
1
0
Number

INPUTBOX
2104
774
2259
834
care_attitude
0.5
1
0
Number

INPUTBOX
2107
842
2262
902
self_capacity
0.8
1
0
Number

MONITOR
2142
448
2256
493
Potential contacts
PotentialContacts
0
1
11

MONITOR
999
946
1101
991
NIL
numberInfected
17
1
11

PLOT
2306
422
2641
545
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
2139
503
2295
564
se_illnesspd
4.0
1
0
Number

INPUTBOX
2139
566
2295
627
se_incubation
2.25
1
0
Number

PLOT
2308
543
2646
665
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
2309
665
2469
786
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
1942
775
2097
835
initialassociationstrength
0.0
1
0
Number

SLIDER
700
392
902
425
AsymptomaticPercentage
AsymptomaticPercentage
0
100
34.64533499995429
1
1
NIL
HORIZONTAL

MONITOR
1245
630
1310
675
Virulence
mean [ personalvirulence] of simuls
1
1
11

SLIDER
700
776
906
809
Global_Transmissability
Global_Transmissability
0
100
25.0
1
1
NIL
HORIZONTAL

MONITOR
1320
630
1376
675
A V
mean [ personalvirulence ] of simuls with [ asymptom < AsymptomaticPercentage ]
1
1
11

SLIDER
338
456
514
489
Essential_Workers
Essential_Workers
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
140
1076
313
1109
SeedTicks
SeedTicks
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
336
492
511
525
Ess_W_Risk_Reduction
Ess_W_Risk_Reduction
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
339
420
515
453
App_Uptake
App_Uptake
0
100
100.0
1
1
NIL
HORIZONTAL

SWITCH
342
172
447
205
tracking
tracking
0
1
-1000

SLIDER
461
305
573
338
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
342
383
464
416
schoolsPolicy
schoolsPolicy
0
1
-1000

MONITOR
451
168
523
213
Household
mean [ householdunit ] of simuls
1
1
11

PLOT
2235
123
2515
271
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
503
898
631
931
AssignAppEss
AssignAppEss
1
1
-1000

SLIDER
503
859
631
892
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
343
132
506
165
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
1400
1070
1516
1115
Link Proportion
count links with [ color = blue ] / count links with [ color = red ]
1
1
11

MONITOR
2238
280
2370
325
EW Infection %
EWInfections / 2500
1
1
11

MONITOR
2239
330
2372
375
Student Infections %
studentInfections / 2500
1
1
11

SWITCH
469
383
621
416
SchoolPolicyActive
SchoolPolicyActive
0
1
-1000

SLIDER
520
420
652
453
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
340
342
450
375
MaskPolicy
MaskPolicy
0
1
-1000

SLIDER
523
136
696
169
ResidualCautionPPA
ResidualCautionPPA
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
525
172
698
205
ResidualCautionPTA
ResidualCautionPTA
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
2109
911
2265
944
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
2113
953
2368
1103
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
2283
809
2341
854
R Sum
sum [ r ] of simuls with [ color != 85 ]
1
1
11

MONITOR
2445
810
2495
855
>3
sum [ r ] of simuls with [ color != 85  and R = 3]
17
1
11

MONITOR
2392
810
2442
855
=2
sum [ r ] of simuls with [ color != 85  and R = 2]
17
1
11

MONITOR
2496
810
2546
855
=4
sum [ r ] of simuls with [ color != 85  and R = 4]
17
1
11

MONITOR
2340
809
2390
854
=1
sum [ r ] of simuls with [ color != 85  and R = 1]
17
1
11

MONITOR
2548
810
2598
855
>4
sum [ r ] of simuls with [ color != 85  and R > 4]
17
1
11

MONITOR
2446
858
2496
903
C3
count simuls with [ color != 85 and R = 3]
17
1
11

MONITOR
2392
858
2442
903
C2
count simuls with [ color != 85 and R = 2]
17
1
11

MONITOR
2499
859
2549
904
c4
count simuls with [ color != 85 and R = 4]
17
1
11

MONITOR
2550
859
2600
904
C>4
count simuls with [ color != 85 and R > 4 ]
17
1
11

MONITOR
2339
858
2389
903
C1
count simuls with [ color != 85 and R = 1]
17
1
11

MONITOR
2283
858
2333
903
C0
count simuls with [ color != 85 and R = 0]
17
1
11

SLIDER
2378
282
2551
315
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
2379
319
2552
352
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
2510
925
2568
970
%>3
count simuls with [ color != 85 and R > 2] / count simuls with [ color != 85 and R > 0 ] * 100
2
1
11

MONITOR
2509
743
2567
788
% R
sum [ R ] of simuls with [ color != 85 and R > 2] / sum [ R ] of simuls with [ color != 85 and R > 0 ] * 100
2
1
11

SLIDER
703
695
905
728
Asymptomatic_Trans
Asymptomatic_Trans
0
1
0.2582628863782269
.01
1
NIL
HORIZONTAL

SWITCH
506
696
686
729
OS_Import_Switch
OS_Import_Switch
1
1
-1000

SLIDER
703
735
905
768
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
1000
889
1072
934
OS %
( count simuls with [  imported = 1 ] / count simuls with [ color != 85 ]) * 100
2
1
11

SLIDER
506
736
694
769
OS_Import_Post_Proportion
OS_Import_Post_Proportion
0
1
0.67
.01
1
NIL
HORIZONTAL

MONITOR
998
998
1106
1043
NIL
currentinfections
17
1
11

MONITOR
1078
890
1153
935
Illness time
mean [ timenow ] of simuls with [ color = red ]
1
1
11

MONITOR
898
1035
1003
1096
ICU Beds
ICUBedsRequired
0
1
15

SWITCH
462
347
587
380
Complacency
Complacency
0
1
-1000

CHOOSER
1270
763
1363
808
InitialScale
InitialScale
0 1 2 3 4
0

CHOOSER
506
776
694
821
Stage
Stage
0 1 2 3 3.3 3.4 3.5 3.9 4
8

PLOT
2378
981
2623
1103
New cases in last 7, 14, 28 days
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
"default" 1.0 0 -16777216 true "" "plot casesinperiod14"
"pen-1" 1.0 0 -7500403 true "" "plot casesinperiod7"
"pen-2" 1.0 0 -2674135 true "" "plot casesinperiod28"

INPUTBOX
1425
133
1505
194
zerotoone
1.0
1
0
Number

INPUTBOX
1423
196
1503
257
onetotwo
35.0
1
0
Number

INPUTBOX
1423
258
1505
319
twotothree
56.0
1
0
Number

INPUTBOX
1423
320
1505
381
threetofour
210.0
1
0
Number

SWITCH
506
658
618
691
SelfGovern
SelfGovern
1
1
-1000

PLOT
1396
498
1921
619
Stages
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
"default" 1.0 0 -5298144 true "" "plot stage"

MONITOR
2379
926
2494
971
Cases in period 7
casesinperiod7
0
1
11

INPUTBOX
1508
132
1590
193
JudgeDay1
2.0
1
0
Number

INPUTBOX
1508
198
1591
259
JudgeDay2
2.0
1
0
Number

INPUTBOX
1509
260
1591
321
JudgeDay3
2.0
1
0
Number

INPUTBOX
1509
322
1591
383
JudgeDay4
2.0
1
0
Number

MONITOR
1417
548
1527
593
Policy Reset Date
ResetDate
0
1
11

INPUTBOX
2140
632
2296
693
UpperStudentAge
18.0
1
0
Number

INPUTBOX
2142
693
2298
754
LowerStudentAge
4.0
1
0
Number

PLOT
512
493
692
643
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
508
823
681
856
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
963
472
1136
505
outsideRisk
outsideRisk
0
100
33.0
1
1
NIL
HORIZONTAL

MONITOR
330
76
413
121
Green space
count patches with [ pcolor = green ]
0
1
11

INPUTBOX
1829
132
1902
193
onetozero
0.0
1
0
Number

INPUTBOX
1831
193
1903
254
twotoone
1.0
1
0
Number

INPUTBOX
1831
255
1901
316
threetotwo
35.0
1
0
Number

INPUTBOX
1831
316
1903
377
fourtothree
105.0
1
0
Number

MONITOR
229
888
311
933
Yellow (raw)
count simuls with [ color = yellow ]
0
1
11

MONITOR
1432
605
1550
650
NIL
StageHasChanged
0
1
11

INPUTBOX
1754
134
1824
194
JudgeDay1_d
1.0
1
0
Number

INPUTBOX
1754
195
1828
255
Judgeday2_d
1.0
1
0
Number

INPUTBOX
1754
257
1831
317
Judgeday3_d
1.0
1
0
Number

INPUTBOX
1754
320
1829
380
Judgeday4_d
1.0
1
0
Number

SLIDER
423
83
603
116
Undetected_Proportion
Undetected_Proportion
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
52
830
167
875
Undetected Cases
count simuls with [ color = red and undetectedFlag = 1 ]
0
1
11

MONITOR
340
922
412
967
NIL
Dailycases
0
1
11

SLIDER
756
86
929
119
Household_Attack
Household_Attack
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
80
335
153
380
Time = 1 
count simuls with [ timenow = 2 ]
0
1
11

MONITOR
1529
549
1594
594
Students
count simuls with [ studentFlag = 1 ]
0
1
11

SLIDER
616
86
735
119
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
1613
139
1728
184
Last Decision Date
DecisionDate
0
1
11

SWITCH
962
87
1066
120
Isolate
Isolate
0
1
-1000

SLIDER
1155
88
1343
121
Mask_Efficacy_Discount
Mask_Efficacy_Discount
0
1
0.33
.01
1
NIL
HORIZONTAL

SWITCH
1398
80
1524
113
Vaccine_Avail
Vaccine_Avail
0
1
-1000

SLIDER
1532
82
1705
115
Vaccine_Rate
Vaccine_Rate
0
700
2.73
1
1
NIL
HORIZONTAL

SLIDER
1710
82
1883
115
Vaccine_Efficacy
Vaccine_Efficacy
0
100
94.0
1
1
NIL
HORIZONTAL

CHOOSER
1893
72
2032
117
BaseStage
BaseStage
0 1 2 3 4
1

MONITOR
58
776
147
821
Mean ID Time
meanIDTime
1
1
11

SLIDER
2038
80
2211
113
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
2220
70
2359
115
MaxStage
MaxStage
0 1 2 3 4
4

MONITOR
1533
33
1623
78
Vaccinated %
( count simuls with [ shape = \"person\" ] / 2500 )* 100
2
1
11

CHOOSER
2363
72
2502
117
Vaccine_Type
Vaccine_Type
"AstraZeneca" "Moderna" "Pfizer/BioNTech" "Other"
1

SLIDER
136
651
309
684
RAND_SEED
RAND_SEED
0
1000000
1235.0
1
1
NIL
HORIZONTAL

SLIDER
1710
40
1888
73
Inf_Curve_Truncation
Inf_Curve_Truncation
0
1
0.29
.01
1
NIL
HORIZONTAL

SLIDER
1158
49
1344
82
PropWithComorbidity
PropWithComorbidity
0
100
20.0
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
    <enumeratedValueSet variable="Vaccine_Avail">
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
    <enumeratedValueSet variable="Vaccine_Avail">
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
    <enumeratedValueSet variable="Vaccine_Avail">
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
