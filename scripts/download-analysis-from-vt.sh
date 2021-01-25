#!/bin/bash

# Input:
# 1. date of results to download
# 2. download folder [optional - defaults to /data/results]

# Logic:
# 1. Fetch from the Github Repository the content of the folder associated with the date.
# 2. For each file in the folder, if not downloaded already ( check in download folder ) get from virus total its analysis.
# 3. If analysis found no issue with the uploaded file, download the file to the results folder under {upload-date}/{hashid} and unzip it.
# 4. parse the sysflow results.

function usage()
{
    echo -n "
    Download non-malicious VirusTotal scanned Sysflow analysis results 

    Usage:
      ./download-from-vt.sh --download-date <DOWNLOAD_DATE> [--download-folder <DOWNLOAD_FOLDER>]

    Options:
        --help                              Show this screen
        --download-date <DOWNLOAD_DATE>     The analyze date to download in format of YYYY-MM-DD
        --download-folder <DOWNLOAD_FOLDER> [optional] The base folder to save downloaded results.
                                            Defaults to /data/results.    
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
            --download-date)
            DOWNLOAD_DATE="$2"
            shift 2
            ;;
      			--download-folder)
            DOWNLOAD_FOLDER="$2"
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

function validate()
{
    if [[ -z ${DOWNLOAD_DATE} ]];
    then
        usage
        exit 0
    fi
}

function log(){
  echo "[$(date +%FT%T)] - $1"
}

parse_args "$@"

validate

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
source ${SCRIPT_FOLDER}/secrets.env
source ${SCRIPT_FOLDER}/utils.sh

SYSFLOW_CONTAINER_OUTPUT_FILENAME=sysflow.log
SYSFLOW_CONTAINER_OUTPUT_PATH=/mnt/data
DOWNLOAD_FOLDER=${DOWNLOAD_FOLDER:-$DEFAULT_DOWNLOAD_VT_ANALYSIS_FOLDER}
mkdir -p ${DOWNLOAD_FOLDER}/${DOWNLOAD_DATE}
exec 1>>${DOWNLOAD_FOLDER}/${DOWNLOAD_DATE}/download.log 2>&1

log "$(seq 40 | sed 's/.*/*/' | tr -d '\n') START $(seq 40 | sed 's/.*/*/' | tr -d '\n')"
log "Fetching all content in Github Repository for date ${DOWNLOAD_DATE}"
RESPONSE_GITHUB_CONTENT=$(
  curl --silent \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/cwp-jd/vt-hash-ids/contents/${DOWNLOAD_DATE})

REPO_ROOT_DIRECTORY_CONTENT=($( echo ${RESPONSE_GITHUB_CONTENT} | jq -c -r '.[] | select(.type? == "file")'))
if [ ${#REPO_ROOT_DIRECTORY_CONTENT[@]} -eq 0 ]; then
  log "Failed to fetch Github Repository content for date ${DOWNLOAD_DATE} due to $( echo ${RESPONSE_GITHUB_CONTENT} | jq -c '.' )"
  exit 
fi

for ITEM in ${REPO_ROOT_DIRECTORY_CONTENT[@]}
do
  NAME=$( echo ${ITEM} | jq '.name' | sed "s/\"//g" )
  GITHUB_REL_PATH=$( echo ${ITEM} | jq '.path' | sed "s/\"//g" )
  FOLDER=$( readlink -f "${DOWNLOAD_FOLDER}/${DOWNLOAD_DATE}/${NAME}" )
  if [[ ! -d ${FOLDER} ]]; then
    log "Fetching Virus Total Analysis for ${GITHUB_REL_PATH}"
    mkdir -p ${FOLDER}
    ANALYSIS_RESULT=$(curl --silent --request GET --url https://www.virustotal.com/api/v3/files/${NAME} --header "x-apikey: ${VT_API_KEY}")
    echo "${ANALYSIS_RESULT}" > ${FOLDER}/vt-analysis.json
    IS_MALICIOUS=$(echo ${ANALYSIS_RESULT} | jq '.data.attributes.last_analysis_stats.malicious') 
    if [ ${IS_MALICIOUS} == "0" ]; then
      log "Downloading ${GITHUB_REL_PATH} from Virus Total"
      curl --silent --request GET -L \
        --url https://www.virustotal.com/api/v3/files/${NAME}/download \
        --header "x-apikey: ${PREMIUM_VT_API_KEY}" \
        --output ${FOLDER}/temp.zip
      log "Uncompressing ${GITHUB_REL_PATH}/temp.zip"
      unzip -q ${FOLDER}/temp.zip -d ${FOLDER}
      log "Parsing all Sysflow Analysis logs found under ${GITHUB_REL_PATH}"
      cd ${FOLDER}
      FOLDER_DIRECTORIES=$(ls -d */)
      for DIRECTORY in ${FOLDER_DIRECTORIES}
      do 
        NEW_DIRECTORY=${DIRECTORY/_//}
        mkdir -p $NEW_DIRECTORY
        docker run \
            --rm \
            -v ${PWD}/${DIRECTORY}:${SYSFLOW_CONTAINER_OUTPUT_PATH} \
            sysflowtelemetry/sysprint -o json -w ${SYSFLOW_CONTAINER_OUTPUT_PATH}/${SYSFLOW_CONTAINER_OUTPUT_FILENAME} ${SYSFLOW_CONTAINER_OUTPUT_PATH}
        mv $DIRECTORY/* $NEW_DIRECTORY
        rm -rf $DIRECTORY
      done
      cd -
    else 
      log "Not downloading ${GITHUB_REL_PATH} from Virus Total, since at least one virus total engine found ${GITHUB_REL_PATH} to be malicious"
    fi 
  else
    log "Not Fetching Virus Total Analysis for ${GITHUB_REL_PATH} since already exsits"
  fi
done
log "$(seq 41 | sed 's/.*/*/' | tr -d '\n') END $(seq 41 | sed 's/.*/*/' | tr -d '\n')"