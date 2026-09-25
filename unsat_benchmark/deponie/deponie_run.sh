#!/bin/sh

MY_UG4_ROOT="/Users/anaegel/Software/d3f-ug4"

run_case() {
    CASE=$1
    mkdir -p deponie_case$CASE
    cd deponie_case$CASE
    echo "Running deponie case $CASE in $PWD"
    ln -sf ${MY_UG4_ROOT}/apps/d3f_plusplus_app/unsat_benchmark/deponie/CP_Unsaturated.1.ug4cp
    mpirun -np 6 ${MY_UG4_ROOT}/bin/ugshell -ex d3f_plusplus_app/unsat_benchmark/deponie/deponie.lua -fromCP 1 --case $CASE --path ${PWD} 3>&1 | tee deponie_case$CASE.log
    cd ..
}

#for CASE in $(seq 1 7); do
#    run_case $CASE
#done


#run_case 1 # case 1 
#cd deponie_case1
#python deponie_plot.py --pdf --output tracer_plot_case1.pdf --T 1.1e+9
#cd ..

run_case 2 # case 1 
#cd deponie_case2    
#python deponie_plot.py --pdf --output tracer_plot_case2.pdf --T 1.1e+9
#cd ..

run_case 3 # case 1 
#cd deponie_case3    
#python deponie_plot.py --pdf --output tracer_plot_case3.pdf --T 2.1e+9
#cd ..
