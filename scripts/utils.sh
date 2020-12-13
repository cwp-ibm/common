#!/bin/bash

export SYSFLOW_CONTAINER_OUTPUT_FILENAME=sysflow.log
export SYSFLOW_CONTAINER_OUTPUT_PATH=/mnt/data

function generate_container_name() {
    local DOCKER_IMAGE=$1
    CONTAINER_NAME=${DOCKER_IMAGE//[:.]/_}
}