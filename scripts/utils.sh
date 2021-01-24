#!/bin/bash

function exit_on_error() {
  exit_code=$1
  last_command=${@:2}
  if [ $exit_code -ne 0 ]; then
    >&2 log "\"${last_command}\" command failed with exit code ${exit_code}."
    exit $exit_code
  fi
}

function create_account() {
  local __UNIQUE_ID=`shuf --input-range=100000-999999 --head-count=1`
  local __USER_NAME="malware-docker-${__UNIQUE_ID}"
  local __USER_EXISTS=$(getent passwd ${__USER_NAME})
  if [[ -z ${__USER_EXISTS} ]]; # Create User if does not exists
  then
      echo "*** Creating User Account ${__USER_NAME} ***"
      adduser --disabled-password --gecos "${__USER_NAME}" ${__USER_NAME}
      exit_on_error $? !!
      echo "*** Adding user account ${__USER_NAME} to docker group ***"
      adduser ${__USER_NAME} docker
      exit_on_error $? !!
      echo "*** Removing password from user account ${__USER_NAME} ***"
      passwd --delete ${__USER_NAME}
      exit_on_error $? !!
  fi
  if [[ -n $1 ]];
  then
    local __RESULTVAR=$1
    eval $__RESULTVAR="'$__USER_NAME'"
  fi
}

function delete_account() {
  local __USER_EXISTS=$(getent passwd $1)
  if [[ -n ${__USER_EXISTS} ]]; # Delete User only if exists
  then
    echo "*** Deleting Account $1"
    deluser $1 --remove-home
    exit_on_error $? !!
  fi
}

function log(){
  echo "[$(date +%FT%T)] - $1"
}

set -o history -o histexpand

export DEFAULT_PENDING_ANALYSIS_FOLDER="/data/pending/analysis"
export DEFAULT_DOWNLOAD_FOLDER="/data/results"
export DEFAULT_BASE_DOWNLOAD_FOLDER="/data/malwares"
export DEFAULT_BASE_MALWARES_HASH_LISTS_FOLDER="/data/malwares/hash_lists"
export DEFAULT_MALWARE_DOWNLOAD_SUFFIX_PATH=""
export DEFAULT_PENDING_UPLOAD_FOLDER="/data/pending/upload"
export DEFAULT_OUTPUT_FOLDER="/data/results"
export DEFAULT_PENDING_UPLOAD_FOLDER="/data/pending"
export DEFAULT_VIRUS_TOTAL_HASH_IDS_FOLDER="/data/virus_total"

function create_directory () {
  if [ ! -d $1 ];
  then
    mkdir --parent $1
    exit_on_error $? "mkdir --parent $1"
  fi
}