#!/bin/bash

# Environment variables
CUSTOM_FILE=${CUSTOM_FILE:-"ocaml-versions/custom.json"}
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR:-/tmp}

# Host
HOSTNAME=`hostname`

# Number of Custom variants
COUNT=`jq '. | length' "${CUSTOM_FILE}"` 

# Functions
check_sequential_parallel () {
    if [[ $1 == *"multicore"* ]]; then
        echo "parallel"
    else
        echo "sequential"
    fi
}

check_not_expired () {
    EXPIRY_DATE=$(date -d $1 +%s)
    TODAY=`date +%Y-%m-%d`
    CURRENT_DATE=$(date -d "${TODAY}" +%s)
    if [[ "${CURRENT_DATE}" -le "${EXPIRY_DATE}" ]]; then
        return 0
    else
        return 1
    fi
}         

find_commit () {
    URL=$1
    if [[ ${URL} == *"trunk"* ]]; then
        COMMIT=`git ls-remote https://github.com/ocaml/ocaml.git refs/heads/trunk | awk -F' ' '{print $1}'`
    elif [[ ${URL} == *"refs/heads"* ]]; then
        GIT_SOURCE=`echo ${URL} | awk -F'/archive/' '{print $1}'`
        REFS_PATH=`echo ${URL} | awk -F'/archive/' '{print $2}' | awk -F'.' '{print $1}'`
        COMMIT=`git ls-remote ${GIT_SOURCE} ${REFS_PATH} | awk -F' ' '{print $1}'`
    elif [[ ${URL} == *"archive"* ]]; then
        COMMIT=`echo ${URL##*/} | awk -F'.' '{print $1}'`
    else
        echo "Error: Unable to find commit for ${URL}"
        COMMIT=""
    fi
    echo "${COMMIT}" 
}

# Iterate through each variant
i=0
while [ $i -lt ${COUNT} ]; do
    # Start new build
    make clean

    # Obtain configuration options
    CONFIG_URL=`jq -r '.['$i'].url' "${CUSTOM_FILE}"`
    CONFIG_TAG=`jq -r '.['$i'].tag' "${CUSTOM_FILE}"`
    CONFIG_RUN_JSON=`jq -r '.['$i'].config_json' "${CUSTOM_FILE}"`
    CONFIG_NAME=`jq -r '.['$i'].name' "${CUSTOM_FILE}"`
    CONFIG_OPTIONS=`jq -r '.['$i'].configure // empty' "${CUSTOM_FILE}"`
    CONFIG_RUN_PARAMS=`jq -r '.['$i'].runparams // empty' "${CUSTOM_FILE}"`
    CONFIG_ENVIRONMENT=`jq -r '.['$i'].environment // empty' "${CUSTOM_FILE}"`
    CONFIG_EXPIRY=`jq -r '.['$i'].expiry // empty' "${CUSTOM_FILE}"`
    TAG_STRING=`echo \"${CONFIG_TAG}\"`

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)    
    SEQPAR=$(check_sequential_parallel ${CONFIG_RUN_JSON})
    COMMIT=$(find_commit ${CONFIG_URL})
    NOT_EXPIRED=$(check_not_expired ${CONFIG_EXPIRY})
    
    echo "INFO: ${TIMESTAMP} Running benchmarks for URL=${CONFIG_URL}, CONFIG_TAG=${CONFIG_TAG}, CONFIG_RUN_JSON=${CONFIG_RUN_JSON} for COMMIT=${COMMIT}"
    
    if [[ ! -z "${COMMIT}" ]] && check_not_expired ${CONFIG_EXPIRY} ; then
        # Create results directory
        RESULTS_DIR="${SANDMARK_NIGHTLY_DIR}/sandmark-nightly/${SEQPAR}/${HOSTNAME}/${TIMESTAMP}/${COMMIT}"
        mkdir -p "${RESULTS_DIR}"

        # Prepare run JSON
        TAG=`echo "${TAG_STRING}"` make `echo ${CONFIG_RUN_JSON}`

        # Build and execute benchmarks
        if [[ ${SEQPAR} == "sequential" ]]; then
            USE_SYS_DUNE_HACK=1 SANDMARK_URL="`echo ${CONFIG_URL}`" \
                             RUN_CONFIG_JSON="`echo ${CONFIG_RUN_JSON}`" \
                             ENVIRONMENT="`echo ${CONFIG_ENVIRONMENT}`" \
                             OCAML_CONFIG_OPTION="`echo ${CONFIG_OPTIONS}`" \
                             OCAML_RUN_PARAM="`echo ${CONFIG_RUN_PARAMS}`" \
                             SANDMARK_CUSTOM_NAME="`echo ${CONFIG_NAME}`" \
                             make ocaml-versions/5.00.0+stable.bench > "${RESULTS_DIR}/${CONFIG_NAME}.${TIMESTAMP}.${COMMIT}.log" 2>&1
        else
            USE_SYS_DUNE_HACK=1 SANDMARK_URL="`echo ${CONFIG_URL}`" \
                             RUN_CONFIG_JSON="`echo ${CONFIG_RUN_JSON}`" \
                             ENVIRONMENT="`echo ${CONFIG_ENVIRONMENT}`" \
                             OCAML_CONFIG_OPTION="`echo ${CONFIG_OPTIONS}`" \
                             OCAML_RUN_PARAM="`echo ${CONFIG_RUN_PARAMS}`" \
                             SANDMARK_CUSTOM_NAME="`echo ${CONFIG_NAME}`" \
                             RUN_BENCH_TARGET=run_orunchrt \
                             BUILD_BENCH_TARGET=multibench_parallel \
                             make ocaml-versions/5.00.0+stable.bench > "${RESULTS_DIR}/${CONFIG_NAME}.${TIMESTAMP}.${COMMIT}.log" 2>&1
        fi

        # Copy results
        cp _results/* "${RESULTS_DIR}"
    else
        echo "WARNING: ${TIMESTAMP}: Not running URL=${CONFIG_URL}, CONFIG_TAG=${CONFIG_TAG}, CONFIG_RUN_JSON=${CONFIG_RUN_JSON} for COMMIT=${COMMIT} and EXPIRY=${CONFIG_EXPIRY}"
    fi
    
    # Next custom variant
    i=$((i+1))
done
