#!/bin/bash

function usage()
{
    echo -n "
    Start Sysflow monitor. 

    Usage:
      ./parse_sysflow_monitor_result.sh --sysflow-output-folder <SYSFLOW_OUTPUT_FOLDER>

    Options:
      --help                                            Show this screen
      --sysflow-output-folder <SYSFLOW_OUTPUT_FOLDER>   The folder containing the sysflow output 
    "
    echo
}

function parse_args()
{
    if [[ "$#" -eq 0 ]]; then
        usage
        exit 1
    fi

    while (( "$#" )); do
        case "$1" in
            --sysflow-output-folder)
            LOCALHOST_SYSFLOW_OUTPUT_FOLDER="$2"
            shift 2
            ;;
            --help)
            echo "--help"
            usage
            exit 0
            ;;
            --) # end argument parsing
            echo "--"
            shift
            break
            ;;
            -*|--*) # unsupported flags
            echo "-*|--*"
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
            *) # preserve positional arguments
            echo "*"
            PARAMS="$PARAMS $1"
            shift
            ;;
        esac
    done
}

parse_args "$@"

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))

source ${SCRIPT_FOLDER}/utils.sh

echo "*** Running SysPrint ***"

docker run \
    --rm \
    -v ${LOCALHOST_SYSFLOW_OUTPUT_FOLDER}:${SYSFLOW_CONTAINER_OUTPUT_PATH} \
    sysflowtelemetry/sysprint -o json -w ${SYSFLOW_CONTAINER_OUTPUT_PATH}/${SYSFLOW_CONTAINER_OUTPUT_FILENAME} ${SYSFLOW_CONTAINER_OUTPUT_PATH}

echo "*** Pretifying output for human readability  ***"

jq . ${LOCALHOST_SYSFLOW_OUTPUT_FOLDER}/${SYSFLOW_CONTAINER_OUTPUT_FILENAME} > ${LOCALHOST_SYSFLOW_OUTPUT_FOLDER}/${SYSFLOW_CONTAINER_OUTPUT_FILENAME}.json