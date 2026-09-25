# How to


## Command line options

--saturated
--unsaturated


## Generate initial data.

The example requires a steady-state pressure field. This is computed using

````
ugshell -ex deponie.lua -fromCP 0

´´´
This results in a set of checkpoints 'CP_Unsaturated.nn.ug4cp'.


Select a checkpoint file that has reached steady state. Renanme to 'CP_Unsaturated.1.ug4cp'. Modify the file 'CP_Unsaturated.1.ug4cp/env.lua' and select small time step and time, e.g.:

```
cpenv["myData"]["currdt"] = 1000
cpenv["myData"]["time"] = 1e-6
´´´

Now you have an starting point for forthcoming simulations!

## Run simulations

```
mkdir test
cd test
sh ../deponie_run.sh
´´´

## Post process

Each run results in a set of files 'Tracer_Pn.dat'.

```
cd test/deponie_case1

´´´
