#!/bin/bash

# The Container Image to stop
DOCKER_IMAGE=$1

CONTAINER_NAME=${DOCKER_IMAGE/:/_}

echo "*** Stoping Target Docker ***"

docker container stop ${CONTAINER_NAME}

echo "*** Waiting 10 seconds before Stoping SysFlow Collector ***"

sleep 10

echo "*** Stoping SysFlow Collector ***"

docker container stop sf-collector
