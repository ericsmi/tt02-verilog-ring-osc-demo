#!/bin/sh
# run from /foss/designs/<designs>/run
# It finds all the runs of form RUN_<timestamp>
# runs sta and puts them into a csv

run_sta()
{
    # Get the STA results from a single openlane run
    pwd
    sta -no_splash -exit ../src/sta.ring.tcl 2>null | grep -v Warn
}
cd 
for d in `find  . -maxdepth 1 -name "RUN_*" -a -type d`
do
    cd $d
    # Just grab the text we care about and format it into a csv
    run_sta | awk '$1 ~ /RUN_/ {r=$1}; \
                   $1 ~ /ring0/ {r0n=$1;r0v=$4}; 
                   $1 ~ /ring1/ {print r "," r0n "," r0v "," $1 "," $4} '
    cd ..
done
