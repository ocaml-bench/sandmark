#!/bin/bash

# Environment variables
CUSTOM_FILE=${CUSTOM_FILE:-"ocaml-versions/custom.json"}
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR:-/tmp}
SANDMARK_REPO="https://github.com/ocaml-bench/sandmark.git"
TMP_CUSTOM_FILE=$(mktemp --tmpdir custom.XXXXXXXX.json)
TMP_DIR="/tmp"

# Host
HOSTNAME=`hostname`

# Functions
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
    elif [[ ${URL} == *"refs/head"* || ${URL} == *"refs/pull"* ]]; then
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

is_old_commit () {
    KIND=$1
    HOSTNAME=$2
    COMMIT=$3
    REPO_DIR="${SANDMARK_NIGHTLY_DIR}/sandmark-nightly"
    git -C "${REPO_DIR}" checkout -B main origin/main
    BENCH_PATH="${KIND}/${HOSTNAME}/*/${COMMIT}/*.summary.bench"
    # NOTE: git ls-files doesn't change the exit code whether or not any files
    # are found. So, we grep for files with summary.bench in their name, and
    # use its exit code.
    git -C "${REPO_DIR}" ls-files "${BENCH_PATH}"|grep -o "summary.bench" > /dev/null
    OLD=$?
    git -C "${REPO_DIR}" checkout -B testing origin/testing
    return $OLD
}

# Set build and run parameters for either sequential or parallel benchmarks

config_sequential () {
    CONFIG_BUILD_BENCH_TARGET="buildbench"
    CONFIG_RUN_JSON="run_config_filtered.json"
    return 0
}

config_parallel () {
    CONFIG_BUILD_BENCH_TARGET="multibench_parallel"
    if [ "${HOSTNAME}" == "navajo" ]; then
        CONFIG_RUN_JSON="multicore_parallel_navajo_run_config_filtered.json"
    else
        CONFIG_RUN_JSON="multicore_parallel_run_config_filtered.json"
    fi
    return 0
}

# Override with raw GitHub configuration file (if provided)
if [[ ${CUSTOM_FILE} == *"github"* ]]; then
    wget -O "${TMP_CUSTOM_FILE}" "${CUSTOM_FILE}"
    CUSTOM_FILE=$(echo "${TMP_CUSTOM_FILE}")
fi

# Number of Custom variants
COUNT=`jq '. | length' "${CUSTOM_FILE}"`


# Iterate through each variant
for i in $(seq 0 $((${COUNT} - 1))); do
    # Iterate through each kind of benchmark
    for KIND in "sequential" "parallel" "perfstat" "pausetimes_seq" "pausetimes_par" ; do
        # Obtain configuration options
        CONFIG_URL=`jq -r '.['$i'].url' "${CUSTOM_FILE}"`
        CONFIG_NAME=`jq -r '.['$i'].name' "${CUSTOM_FILE}"`
        CONFIG_VARIANT=$(grep -oP "^(\\d|\.)+(\\+(trunk|stable))*" <<< "${CONFIG_NAME}")
        CONFIG_EXPIRY=`jq -r '.['$i'].expiry // empty' "${CUSTOM_FILE}"`
        CONFIG_TAG=`jq -r '.['$i'].tag // "macro_bench"' "${CUSTOM_FILE}"`
        CONFIG_NAME="${CONFIG_NAME}+${KIND}"

        # Set configuration flags according to the kind of benchmark we're
        # running
        case ${KIND} in
            sequential)
                CONFIG_RUN_BENCH_TARGET="run_orun"
                config_sequential
                ;;
            parallel)
                CONFIG_RUN_BENCH_TARGET="run_orunchrt"
                config_parallel
                ;;
            perfstat)
                CONFIG_RUN_BENCH_TARGET="run_perfstat"
                config_sequential
                ;;
            pausetimes_seq)
                CONFIG_RUN_BENCH_TARGET="run_pausetimes"
                config_sequential
                ;;
            pausetimes_par)
                CONFIG_RUN_BENCH_TARGET="run_pausetimes"
                config_parallel
                ;;
            *)
                echo "Unknown kind ${KIND}! Skipping"
                continue
                ;;
        esac

        CONFIG_OPTIONS=`jq -r '.['$i'].configure // empty' "${CUSTOM_FILE}"`
        CONFIG_RUN_PARAMS=`jq -r '.['$i'].runparams // empty' "${CUSTOM_FILE}"`
        CONFIG_ENVIRONMENT=`jq -r '.['$i'].environment // empty' "${CUSTOM_FILE}"`
        CONFIG_OVERRIDE_PACKAGES=`jq -r '.['$i'].override_packages // empty' "${CUSTOM_FILE}"`
        CONFIG_REMOVE_PACKAGES=`jq -r '.['$i'].remove_packages // empty' "${CUSTOM_FILE}"`
        TAG_STRING=`echo \"${CONFIG_TAG}\"`

        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        COMMIT=$(find_commit ${CONFIG_URL})
        NOT_EXPIRED=$(check_not_expired ${CONFIG_EXPIRY})

        echo "INFO: ${TIMESTAMP} Running benchmarks for URL=${CONFIG_URL}, CONFIG_TAG=${CONFIG_TAG}, CONFIG_RUN_JSON=${CONFIG_RUN_JSON}, KIND=${KIND} for COMMIT=${COMMIT}"

        if [[ ! -z "${COMMIT}" ]] && check_not_expired ${CONFIG_EXPIRY} && ! is_old_commit "${KIND}" "${HOSTNAME}" "${COMMIT}"; then
            # Create results directory
            RESULTS_DIR="${SANDMARK_NIGHTLY_DIR}/sandmark-nightly/${KIND}/${HOSTNAME}/${TIMESTAMP}/${COMMIT}"
            mkdir -p "${RESULTS_DIR}"

            # Clone fresh copy of Sandmark
            CWD=$(pwd)
            cd "${TMP_DIR}"; git clone "${SANDMARK_REPO}"; cd sandmark

            # Prepare run JSON
            TAG=`echo "${TAG_STRING}"` make `echo ${CONFIG_RUN_JSON}`

            # Build and execute benchmarks
            USE_SYS_DUNE_HACK=1 SANDMARK_URL="`echo ${CONFIG_URL}`" \
                RUN_CONFIG_JSON="`echo ${CONFIG_RUN_JSON}`" \
                ENVIRONMENT="`echo ${CONFIG_ENVIRONMENT}`" \
                OCAML_CONFIG_OPTION="`echo ${CONFIG_OPTIONS}`" \
                OCAML_RUN_PARAM="`echo ${CONFIG_RUN_PARAMS}`" \
                SANDMARK_CUSTOM_NAME="`echo ${CONFIG_NAME}`" \
                SANDMARK_OVERRIDE_PACKAGES="`echo ${CONFIG_OVERRIDE_PACKAGES}`" \
                SANDMARK_REMOVE_PACKAGES="`echo ${CONFIG_REMOVE_PACKAGES}`" \
                RUN_BENCH_TARGET="`echo ${CONFIG_RUN_BENCH_TARGET}`" \
                BUILD_BENCH_TARGET="`echo ${CONFIG_BUILD_BENCH_TARGET}`" \
                make ocaml-versions/"${CONFIG_VARIANT}".bench > "${RESULTS_DIR}/${CONFIG_NAME}.${TIMESTAMP}.${COMMIT}.log" 2>&1

            # Copy results
            ls _results/*
            cp _results/* "${RESULTS_DIR}"

            cd "${CWD}"
            rm -rf "${TMP_DIR}/sandmark"
        else
            echo "WARNING: ${TIMESTAMP}: Not running URL=${CONFIG_URL}, CONFIG_TAG=${CONFIG_TAG}, CONFIG_RUN_JSON=${CONFIG_RUN_JSON} for COMMIT=${COMMIT} and EXPIRY=${CONFIG_EXPIRY}"
        fi
    done
done

# Cleanup
rm -f "${TMP_CUSTOM_FILE}"
