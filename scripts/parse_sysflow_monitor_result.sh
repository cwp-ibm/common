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
            SYSFLOW_OUTPUT_FOLDER="$2"
            shift 2
            ;;
            --help)
            usage
            exit 0
            ;;
            --) # end argument parsing
            shift
            break
            ;;
            -*|--*) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
            *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
        esac
    done
}

parse_args "$@"

echo "*** Running SysPrint ***"

docker run \
    --rm \
    -v ${SYSFLOW_OUTPUT_FOLDER}:/mnt/data \
    sysflowtelemetry/sysprint -o json -w /mnt/data/test_scenario /mnt/data

echo "*** Pretifying output for human readability  ***"

jq . ${SYSFLOW_OUTPUT_FOLDER}/test_scenario > ${SYSFLOW_OUTPUT_FOLDER}/test_scenario.json