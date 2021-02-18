#!/bin/bash

function usage()
{
    echo -n "
    Perform Sysflow Analyis on files located in <PENDING_ANALYSIS_FOLDER>. 

    Usage:
      ./multiple-docker-malware-analysis.sh [--pending-analysis-folder <PENDING_ANALYSIS_FOLDER>]
                                            [--max-duration <MAX-DURATION>] 
                                            [--output <OUTPUT>] 
                                            [--pending-upload-folder <PENDING_UPLOAD_FOLDER>]
                                            [--override-dockerfile] 

    Options:
      --help                                                Show this screen
      --pending-analysis-folder <PENDING_ANALYSIS_FOLDER>   [optional] The folder path containing symbolic links to executables for analyze
                                                            Default: ${DEFAULT_BASE_PENDING_ANALYSIS_FOLDER}
      --max-duration <MAX-DURATION>                         [optional] The max duration in seconds to perform Sysflow Analysis on each malware
                                                            Default: ${DEFAULT_MAX_MALWARE_DOCKER_RUN_DURATION} seconds.
      --output <OUTPUT>                                     [optional] The base folder to save analysis outputs
                                                            Default: ${DEFAULT_SYSFLOW_ANALYSIS_OUTPUT_FOLDER}.   
      --pending-upload-folder <PENDING_UPLOAD_FOLDER>       [optional] The folder to save symbolic link to analysis results
                                                            Default: ${DEFAULT_PENDING_UPLOAD_FOLDER}
      --override-dockerfile                                 [optional] Override the Dockerfile
    "
    echo
}

function parse_args()
{
    while (( "$#" )); do
        case "$1" in
            --pending-analysis-folder)
            PENDING_ANALYSIS_FOLDER="$2"
            shift 2
            ;;
            --max-parallel-analysis)
            MAX_RUNNING_JOBS="$2"
            shift 2
            ;;
            --output)
            OUTPUT_FOLDER="$2"
            shift 2
            ;;
            --pending-upload-folder)
            PENDING_UPLOAD_FOLDER="$2"
            shift 2
            ;;
            --help)
            usage
            exit 0
            ;;
            *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
        esac
    done
}

function running_jobs() {
    local __RESULTVAR=$1
    local __JOBS=`jobs -r -p`    
    local __JOBS_COUNTER=0
    for JOB in $__JOBS
    do
      ((__JOBS_COUNTER=__JOBS_COUNTER+1))
    done
    eval $__RESULTVAR="'$__JOBS_COUNTER'"
}

function main()
{
  SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
  source ${SCRIPT_FOLDER}/utils.sh

  parse_args "$@"
  exit_if_not_sudo

  PENDING_ANALYSIS_FOLDER=${PENDING_ANALYSIS_FOLDER:-$DEFAULT_BASE_PENDING_ANALYSIS_FOLDER}
  PENDING_UPLOAD_FOLDER=${PENDING_UPLOAD_FOLDER:-$DEFAULT_PENDING_UPLOAD_FOLDER}

  MALWARE_FILE_NAMES=(`find ${PENDING_ANALYSIS_FOLDER} -type l`)
  TOTAL_MALWARES_COUNTER=${#MALWARE_FILE_NAMES[@]}
  NEXT_MALWARE_INDEX=0
  CURRENT_TIME=$(date +%Y-%m-%dT%H-%M-%S)
  
  while [ $NEXT_MALWARE_INDEX -lt $TOTAL_MALWARES_COUNTER ]
  do
    MALWARE_FILE_NAME=${MALWARE_FILE_NAMES[NEXT_MALWARE_INDEX]}
    EXECUTABLE_RELATIVE_PATH=$(dirname $(echo ${MALWARE_FILE_NAME} | sed "s|${PENDING_ANALYSIS_FOLDER}/||"))
    EXECUTABLE=`readlink -f ${MALWARE_FILE_NAMES[NEXT_MALWARE_INDEX]}`
    log "Starting to analysis ${EXECUTABLE}"
    EXECUTABLE_OUTPUT_FOLDER=${OUTPUT_FOLDER:-${DEFAULT_SYSFLOW_ANALYSIS_OUTPUT_FOLDER}}
    ${SCRIPT_FOLDER}/single-docker-malware-analysis.sh --executable ${EXECUTABLE} \
                                                        --output ${EXECUTABLE_OUTPUT_FOLDER} \
                                                        --pending-upload-folder ${PENDING_UPLOAD_FOLDER} \
                                                        --output-relative-path ${EXECUTABLE_RELATIVE_PATH} \
                                                        --runtime ${CURRENT_TIME} $PARAMS

    [ -L ${MALWARE_FILE_NAME} ] && unlink ${MALWARE_FILE_NAME}
    exit_on_error $?
    NEXT_MALWARE_INDEX=$(($NEXT_MALWARE_INDEX + 1))
  done
}

main "$@"