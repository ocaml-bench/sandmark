#!/bin/bash

OPT_WAIT=$1
START_TIME=$2

loadavg () {
    awk '{print 100*$1}' /proc/loadavg 
}

if [ $OPT_WAIT = 1 ]; then 
    sleep 60
    while [ $(loadavg) -gt 60 ]; do 
        if [ $(expr $(date +%s) - $START_TIME) -gt $(expr 3600 \* 12) ]; then 
            echo "Could not start for the past 12 hours; aborting run" >&2; 
            exit 10; 
        else 
            echo "System load detected, waiting to run bench (retrying in 5 minutes)"; 
            echo "Loadavg: $(loadavg)"; 
            wall "It's bench startup time, but the load is too high. Please clear the way!"; 
            sleep 300; 
        fi; 
    done; 
fi
