#!/bin/bash

function usage()
{
    echo -n "
    Upload Pending Sysflow analysis results to Virus Total (VT) and save VT hash Id to git repository.

    Usage:
      ./upload-pending.sh [--pending-upload-folder <PU_FOLDER>] 
                          [--virus-total-folder <VT_FOLDER>]
                          [--vt-uploads-folder <VT_UPLOADS_FOLDER>]

    Options:
        --help                                          Show this screen
        --pending-upload-folder <PU_FOLDER>             [optional] The path to the pending upload results.
                                                        Default: ${DEFAULT_PENDING_UPLOAD_FOLDER}
        --virus-total-folder <VT_FOLDER>                [optional] The path to Git VT Hash ids repository.
                                                        Default: ${DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER}
        --vt-uploads-folder <VT_UPLOADS_FOLDER>         [optional] The folder containing the uploaded file to Virus Total
                                                        Default: ${DEFAULT_VT_UPLOADS_FOLDER}
    "
    echo
}

function parse_args()
{
    while (( "$#" )); do
        case "$1" in
            --pending-upload-folder)
            PENDING_UPLOAD_FOLDER="$2"
            shift 2
            ;;
            --virus-total-folder)
            VIRUS_TOTAL_HASH_IDS_FOLDER="$2"
            shift 2
            ;;
            --vt-uploads-folder)
            VT_UPLOADS_FOLDER="$2"
            shift 2
            ;;
            --help)
            usage
            exit 0
            ;;
            --dry-run)
            DRY_RUN=true
            shift 1
            ;;
            --max-sysflow-analyis-file-size)
            MAX_SYSFLOW_ANALYIS_FILE_SIZE="$2"
            shift 1
            ;;
            *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
        esac
    done
}

function validate() 
{
  [ ${PENDING_UPLOAD_FOLDER} == ${DEFAULT_PENDING_UPLOAD_FOLDER} ] && exit_if_not_sudo;
  [ ${VIRUS_TOTAL_HASH_IDS_FOLDER} == ${DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER} ] && exit_if_not_sudo;
  [ ${VT_UPLOADS_FOLDER} == ${DEFAULT_VT_UPLOADS_FOLDER} ] && exit_if_not_sudo;

  create_directory ${PENDING_UPLOAD_FOLDER}
  create_directory ${VIRUS_TOTAL_HASH_IDS_FOLDER}
  create_directory ${VT_UPLOADS_FOLDER}

  if [[ -z ${VT_API_KEY} || -z ${GITHUB_USERNAME} || -z ${GITHUB_PASSWORD} ]];
  then
    log "Missing one of the following environment variables: VT_API_KEY, GITHUB_USERNAME, GITHUB_PASSWORD"
    exit 1
  fi
}

function upload_to_VT() 
{
  local __FULL_FILE_PATH=$1
  if [ $DRY_RUN != true ]
  then
    log "*** Uploading ${__FULL_FILE_PATH} to Virus Total ***"
    local __VT_UPLOAD_RESPONSE=$(curl --request POST \
      --url https://www.virustotal.com/api/v3/files \
      --header "x-apikey: ${VT_API_KEY}" \
      --form file=@${__FULL_FILE_PATH})
    local __VT_HASH_ID=$(echo $__VT_UPLOAD_RESPONSE | jq .data.id | sed "s/\"//g" | base64 -d | cut -d: -f1)
  else
    log "*** In dry-run: Uploading ${__FULL_FILE_PATH} to Virus Total ***"
    local __VT_HASH_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)  
  fi
  
  if [[ -n $2 ]];
  then
    local __RESULTVAR=$2
    eval $__RESULTVAR="'$__VT_HASH_ID'"
  fi
}

function push_to_github()
{
  local __CURRENT_DATE=$(date +%Y-%m-%d)
  local __VT_HASH_ID=$1
  local __HASH_ID_FILE_NAME=${__VT_HASH_ID//\"/''}
  local __HASH_ID_FILE_PATH=${VIRUS_TOTAL_HASH_IDS_FOLDER}/${__CURRENT_DATE}
  if [ $DRY_RUN != true ]
  then
    log "*** Add, Commit and Push Virus Total Hash ID to Git ***"
    mkdir --parents ${__HASH_ID_FILE_PATH}
    touch ${__HASH_ID_FILE_PATH}/${__HASH_ID_FILE_NAME}
    cd ${VIRUS_TOTAL_HASH_IDS_FOLDER}
    git add .
    git commit -m "Add Virus Total Hash ID ${__VT_HASH_ID}"
    git push https://${GITHUB_USERNAME}:${GITHUB_PASSWORD}@github.com/cwp-jd/vt-hash-ids.git
    cd -
  else
    log "*** In dry-run: Add, Commit and Push Total Hash ID ${__HASH_ID_FILE_NAME} to Git ${__HASH_ID_FILE_PATH} ***"
  fi
}

function main() {
  set -e
  SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
  source ${SCRIPT_FOLDER}/secrets.env
  source ${SCRIPT_FOLDER}/utils.sh

  parse_args "$@"

  PENDING_UPLOAD_FOLDER=${PENDING_UPLOAD_FOLDER:-$DEFAULT_PENDING_UPLOAD_FOLDER}
  VIRUS_TOTAL_HASH_IDS_FOLDER=${VIRUS_TOTAL_HASH_IDS_FOLDER:-$DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER}
  VT_UPLOADS_FOLDER=${VT_UPLOADS_FOLDER:-$DEFAULT_VT_UPLOADS_FOLDER}

  validate

  exec >>${VT_UPLOADS_FOLDER}/upload.log 2>&1

  MAX_SYSFLOW_ANALYIS_FILE_SIZE=${MAX_SYSFLOW_ANALYIS_FILE_SIZE:-$DEFAULT_MAX_SYSFLOW_ANALYIS_FILE_SIZE}
  DRY_RUN=${DRY_RUN:-false}
  SYSFLOW_LOG_FILE_PREFIX=sysflow.log.*
  PENDING_UPLOAD_FOLDER_CONTENT_SIZE=${#PENDING_UPLOAD_FOLDER_CONTENT[@]}
  PENDING_UPLOAD_FOLDER_FULLPATH=$(readlink -f ${PENDING_UPLOAD_FOLDER})
  PENDING_UPLOAD_FOLDER_CONTENT=$(find ${PENDING_UPLOAD_FOLDER} -type l)
  CURRENT_DATETIME=$(date +%Y-%m-%dT%H:%M:%S:%3N)
  TEMP_ZIP_FILE_NAME="temp_${CURRENT_DATETIME}.zip"

  RUN_ID=$(date +%Y-%m-%dT%H:%M:%S)
  ANALYSIS_SKIPPED=false

  cd $(readlink -f ${VT_UPLOADS_FOLDER})
  log "$(seq 40 | sed 's/.*/*/' | tr -d '\n') START {${RUN_ID}} $(seq 40 | sed 's/.*/*/' | tr -d '\n')"
  for ITEM in $PENDING_UPLOAD_FOLDER_CONTENT
  do
    RELATIVE_PATH=${ITEM/${PENDING_UPLOAD_FOLDER}\//}
    RELATIVE_PATH_PATH_PARTS=(${RELATIVE_PATH//\// })
    create_directory $(dirname ${RELATIVE_PATH})
    cp -r $(readlink -f ${PENDING_UPLOAD_FOLDER_FULLPATH}/${RELATIVE_PATH}) $(dirname ${RELATIVE_PATH})

    ASC_SORTED_SYSFLOW_LOG_FILES=($(ls -t $(find ${RELATIVE_PATH} -name sysflow.log.*)))
    EARLIST_SYSFLOW_LOG_FILE=${ASC_SORTED_SYSFLOW_LOG_FILES[0]}
    EARLIST_SYSFLOW_LOG_FILE_SIZE=$(stat -c %s ${EARLIST_SYSFLOW_LOG_FILE})
    if [ ${EARLIST_SYSFLOW_LOG_FILE_SIZE} -le $MAX_SYSFLOW_ANALYIS_FILE_SIZE ]
    then
      zip ${TEMP_ZIP_FILE_NAME} ${EARLIST_SYSFLOW_LOG_FILE}
      FILE_SIZE=$(stat -c %s ${TEMP_ZIP_FILE_NAME})
      if [ $FILE_SIZE -gt $DEFAULT_MAX_FILE_SIZE_FOR_VT_UPLOAD ];
      then
        log "*** ${TEMP_ZIP_FILE_NAME} size passed threshold of $DEFAULT_MAX_FILE_SIZE_FOR_VT_UPLOAD, removing last addition ***"
        zip -d ${TEMP_ZIP_FILE_NAME} ${EARLIST_SYSFLOW_LOG_FILE}
        exit_on_error $? "zip ${TEMP_ZIP_FILE_NAME} ${EARLIST_SYSFLOW_LOG_FILE}"
        upload_to_VT ${PWD}/${TEMP_ZIP_FILE_NAME} VT_HASH_ID
        push_to_github ${VT_HASH_ID}
        log "*** Rename ${TEMP_ZIP_FILE_NAME} to ${VT_HASH_ID}.zip"
        mv ${TEMP_ZIP_FILE_NAME} "${VT_HASH_ID}.zip" 
        CURRENT_DATETIME=$(date +%Y-%m-%dT%H:%M:%S:%3N)
        TEMP_ZIP_FILE_NAME="temp_${CURRENT_DATETIME}.zip"
        zip ${TEMP_ZIP_FILE_NAME} ${EARLIST_SYSFLOW_LOG_FILE}
      fi
    else
      if [ $ANALYSIS_SKIPPED == false ]
      then
        ANALYSIS_SKIPPED=true
        log "$(seq 40 | sed 's/.*/*/' | tr -d '\n') START {${RUN_ID}} $(seq 40 | sed 's/.*/*/' | tr -d '\n')" >> upload.skipped.analysis.log
      fi
      log "Skipped uploading analysis of $(dirname $(readlink -f ${PENDING_UPLOAD_FOLDER}/${EARLIST_SYSFLOW_LOG_FILE}))" >> upload.skipped.analysis.log
    fi

    rm -rf ${RELATIVE_PATH_PATH_PARTS[0]}
    [ $DRY_RUN == false ] && unlink ${PENDING_UPLOAD_FOLDER_FULLPATH}/${RELATIVE_PATH}
  done
  
  if [ -f ${TEMP_ZIP_FILE_NAME} ]
  then
    upload_to_VT ${PWD}/${TEMP_ZIP_FILE_NAME} VT_HASH_ID
    push_to_github ${VT_HASH_ID}
    log "*** Rename ${TEMP_ZIP_FILE_NAME} to ${VT_HASH_ID}.zip"
    mv ${TEMP_ZIP_FILE_NAME} "${VT_HASH_ID}.zip"
  fi
  log "$(seq 41 | sed 's/.*/*/' | tr -d '\n') END {${RUN_ID}} $(seq 41 | sed 's/.*/*/' | tr -d '\n')"
  echo

  if [ $ANALYSIS_SKIPPED == true ]
  then
    log "$(seq 41 | sed 's/.*/*/' | tr -d '\n') END {${RUN_ID}} $(seq 41 | sed 's/.*/*/' | tr -d '\n')" >> upload.skipped.analysis.log
    echo >> upload.skipped.analysis.log
  fi
}

main "$@"