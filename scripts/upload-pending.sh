#!/bin/bash

function upload_to_VT() {
  echo "*** Uploading results to Virus Total ***"
  local FULL_FILE_PATH=$1
  local VT_UPLOAD_RESPONSE=$(curl --request POST \
    --url https://www.virustotal.com/api/v3/files \
    --header "x-apikey: ${VT_API_KEY}" \
    --form file=@${FULL_FILE_PATH})
  local VT_HASH_ID=$(echo $VT_UPLOAD_RESPONSE | jq .data.id | sed "s/\"//g" | base64 -d | cut -d: -f1)
  
  echo "*** Add and Push Virus Total Hash ID to Git ***"
  local HASH_ID_FILE_NAME=${VT_HASH_ID//\"/''}
  local HASH_ID_FILE_PATH=${VIRUS_TOTAL_HASH_IDS_FOLDER}/${CURRENT_DATE}
  mkdir --parents ${HASH_ID_FILE_PATH}
  touch ${HASH_ID_FILE_PATH}/${HASH_ID_FILE_NAME}
  cd ${VIRUS_TOTAL_HASH_IDS_FOLDER}
  git add .
  git commit -m "Add Virus Total Hash ID ${VT_HASH_ID}"
  git push https://${GITHUB_USERNAME}:${GITHUB_PASSWORD}@github.com/cwp-jd/vt-hash-ids.git
  cd -
}

function usage()
{
    echo -n "
    Upload Pending Sysflow analysis results to Virus Total (VT) and save VT hash Id to git repository.

    Usage:
      ./upload-pending.sh [--pending-upload-folder <PU_FOLDER>] [--virus-total-folder <VT_FOLDER>]

    Options:
        --help                                          Show this screen
        --pending-upload-folder <PU_FOLDER>             [optional] The path to the pending upload results.
                                                        Default: /data/pending
        --virus-total-folder <VT_FOLDER>                [optional] The path to Git VT Hash ids repository.
                                                        Default: /data/virus_total
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

function validate() 
{
  if [[ ! -d ${PENDING_UPLOAD_FOLDER} ]]; 
  then
    echo "The value for --pending-upload-folder ${PENDING_UPLOAD_FOLDER} is not a directory or does not exist"
    exit 1
  fi

  if [[ ! -d ${VIRUS_TOTAL_HASH_IDS_FOLDER} ]]; 
  then
    echo "The value for --virus-total-folder ${PENDING_UPLOAD_FOLDER} is not a directory or does not exist"
    exit 1
  fi

  if [[ -z ${VT_API_KEY} || -z ${GITHUB_USERNAME} || -z ${GITHUB_PASSWORD} ]];
  then
    echo "Missing one of the following environment variables: VT_API_KEY, GITHUB_USERNAME, GITHUB_PASSWORD"
    exit 1
  fi
}

parse_args "$@"

DEFAULT_PENDING_UPLOAD_FOLDER="/data/pending"
DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER="/data/virus_total"
PENDING_UPLOAD_FOLDER=${PENDING_UPLOAD_FOLDER:-$DEFAULT_PENDING_UPLOAD_FOLDER}
VIRUS_TOTAL_HASH_IDS_FOLDER=${VIRUS_TOTAL_HASH_IDS_FOLDER:-DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER}
SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
source ${SCRIPT_FOLDER}/secrets.env

validate

PENDING_UPLOAD_FOLDER_FULLPATH=$(readlink -f ${PENDING_UPLOAD_FOLDER})
PENDING_UPLOAD_FOLDER_CONTENT=($(ls -t -r ${PENDING_UPLOAD_FOLDER_FULLPATH}))
MAX_UPLOAD_FILE_SIZE=$(( 1024 * 1024 * 32 ));
SYSFLOW_LOG_FILE_PREFIX=sysflow.log.*
DOCKER_LOG_FILE_PATH=Docker/docker.log
TEMP_ZIP_FILE_NAME=temp
PENDING_UPLOAD_FOLDER_CONTENT_SIZE=${#PENDING_UPLOAD_FOLDER_CONTENT[@]}
INDEX=0
CURRENT_DATE=$(date +%Y-%m-%d)

cd ${PENDING_UPLOAD_FOLDER_FULLPATH}
while [ $INDEX -lt ${PENDING_UPLOAD_FOLDER_CONTENT_SIZE} ];
do
    FILE=${PENDING_UPLOAD_FOLDER_CONTENT[$INDEX]}
    echo ${FILE}
    if [[ -L "$FILE" && -d "$FILE" ]];
    then
      zip ${TEMP_ZIP_FILE_NAME} ${FILE}/${SYSFLOW_LOG_FILE_PREFIX} ${FILE}/${DOCKER_LOG_FILE_PATH}
      FILE_SIZE=$(stat -c %s ${TEMP_ZIP_FILE_NAME}.zip)
      if [ $FILE_SIZE -ge $MAX_UPLOAD_FILE_SIZE ];
      then
        echo "passed threshold. removing last addition"
        zip -d ${TEMP_ZIP_FILE_NAME} ${FILE}/${SYSFLOW_LOG_FILE_PREFIX} ${FILE}/${DOCKER_LOG_FILE_PATH}
        echo "upload to virus total"
        upload_to_VT ${PWD}/${TEMP_ZIP_FILE_NAME}.zip   
        echo "delete temp zip file"
        rm ${TEMP_ZIP_FILE_NAME}.zip
      else
        echo "remove link"
        # unlink ${FILE}
        LASTINDEX=$(( $PENDING_UPLOAD_FOLDER_CONTENT_SIZE - 1 ))
        if [ $INDEX -eq $LASTINDEX ];
        then
          echo "upload to virus total"
          upload_to_VT ${PWD}/${TEMP_ZIP_FILE_NAME}.zip
          echo "delete temp zip file"
          rm ${TEMP_ZIP_FILE_NAME}.zip
        fi
        INDEX=$(( $INDEX + 1 ))
      fi
    fi
done