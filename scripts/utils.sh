#!/bin/bash

function generate_container_name() {
    local DOCKER_IMAGE=$1
    CONTAINER_NAME=${DOCKER_IMAGE/:/_}
}