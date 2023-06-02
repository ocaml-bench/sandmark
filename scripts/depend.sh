#!/bin/bash
# Script called before we run the benchmarks.
# Check system & python dependencies.

sys_deps=$1
pip_deps=$2

check_sys_deps () {
    for d in $sys_deps; do
        if ! dpkg-query -W "$d" >/dev/null 2>&1; then
            echo "$d is not installed. Install using your distribution's package manager."
        fi
    done
}

check_pip_deps () {
    for d in $pip_deps; do
        if ! pip3 show "$d" -qq; then
            echo "$d is not installed. Install using \`pip3 install\`."
        fi
    done
}

echo "Checking dependencies..."
check_sys_deps
check_pip_deps
