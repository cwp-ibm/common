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

# set -o history -o histexpand
