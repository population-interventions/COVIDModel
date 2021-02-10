=== population.csv ===
This file defines the characteristics of the agents in the model. There are always 2500 agents, which scale to each represent 10^n people in the population for n \in {0, 1, 2, 3, 4}. Each row is a cohort of agents that have the same basic characteristics.

Many parameters are a boolean, which should be indicated by a value of 1 or 0.

totalAgents sets the size of the cohort. This column must sum to 2500
age sets the singular age of the cohort.
atsi sets whether the cohort are aborigional or torris strait islanders.
disability sets whether the cohort has a disability.
essential sets whether the workers in the cohort are the most essential workers. This causes this cohort to have the highest priority for going to work during a lockdown. For example, say we are in a lockdown where the policy sets 25% of workers to be regarded as essential. If only 15% of the total workers are in an 'essential' cohort, then all of the essential cohort works, with the remaining 10% made up of other workers.
workerCount is how many agents for the cohort are considered to be working age.
phase is the phase in which the cohort is vacinated.
subPhase is the sub phase. Ie the 'a' or 'b' after 1a or 1b
alreadyVaccinated does nothing for the moment, but will be used to let cohorts start vaccinated.

The comment column is for human consumption. It does nothing in the model.

=== vaccine.csv ===
This file configures the phase structure of the simulation. Currently the population in the D column had better match the sums of the populations in each corresponding phase and subPhase in population.csv.

phase is the phase.
subPhase is the letter after the phase, but as a number.
days is the number of days spent in this phase.
population had better match population.csv, as noted above.
name is the name of the vaccine in this phase. It is used by the model to change the non-static parameters in the model.

The comment column is for human consumption. It does nothing in the model.

The rate of vaccination is calculated by the model, and is simply set to population/days. This many vaccines will be offered to agents each day. This value does not need to be an integer, as fractional vaccine is carried between days, avoiding the issues that may arise with small intergers.

incursionScale is a multiplier for the probability of any given infected arrival infecting someone in the community.

infectedArrivals is the number of oppotunities availible to infect a member of the community, per day.
