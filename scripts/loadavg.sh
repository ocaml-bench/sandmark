#!/bin/bash
# Script called before we run the benchmarks.
# Ensure the machine we run on isn't under heavy load.

wait_quiet=$1
start_time=$(date +%s)

loadavg () {
    awk '{print 100*$1}' /proc/loadavg 
}

if $wait_quiet; then 
    wall "It's bench startup time, please clear the way!";
    sleep 60;
    while [ "$(loadavg)" -gt 60 ]; do 
        if [ "$(($(date +%s) - start_time > 3600 * 12))" ]; then 
            echo "Could not start for the past 12 hours; aborting run" >&2;
            exit 10;
        fi;
        echo "System load detected, waiting to run bench (retrying in 5 minutes)";
        echo "Loadavg: $(loadavg)";
        wall "It's bench startup time, but the load is too high. Please clear the way!";
        sleep 300;
    done; 
fi
