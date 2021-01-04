#!/bin/bash

source ./utils.sh

function usage() {
  echo "Usage: $0 create"
  echo "Usage: $0 delete ACCOUNT_TO_DELETE"
}

case "$1" in
  (create) 
    create_account
    exit 0
    ;;
  (delete)
    delete_account $2
    exit 0
    ;;
  (*)
    usage 
    exit 0
    ;;
esac
