#!/bin/bash

# The Docker Image to Monitor
DOCKER_IMAGE=$1

HOSTNAME=local

DOCKER_IMAGE_FOLDER=${DOCKER_IMAGE/:/_}

CONTAINER_NAME=${DOCKER_IMAGE/:/_}

CURRENT_TIME=$(date +%Y-%m-%dT%H-%M-%S)

SYSFLOW_OUTPUT_FOLDER=SysFlow/out/${DOCKER_IMAGE_FOLDER}/${CURRENT_TIME}

mkdir --parents ${SYSFLOW_OUTPUT_FOLDER}

# The location of Sysflow's output
LOCALHOST_VOLUME=${PWD}/${SYSFLOW_OUTPUT_FOLDER}

echo "*** Initializing SysFlow Collector ***"

docker run \
	-t \
	-i \
	--detach \
	--privileged \
	--name sf-collector \
	-v /var/run/docker.sock:/host/var/run/docker.sock \
	-v /dev:/host/dev \
	-v /proc:/host/proc:ro \
	-v /boot:/host/boot:ro \
	-v /lib/modules:/host/lib/modules:ro \
	-v /usr:/host/usr:ro \
	-v ${LOCALHOST_VOLUME}:/mnt/data \
	-e EXPORTER_ID=${HOSTNAME} \
	-e OUTPUT=/mnt/data/test_scenario \
	-e FILTER="container.name!=sf-collector and container.name!=sf-exporter and container.name=${CONTAINER_NAME}" \
	-e INTERVAL=600 \
	--rm \
	 sysflowtelemetry/sf-collector:edge

echo "*** Waiting 10 seconds before Initializing Docker Image ***"

sleep 10

echo "*** Initializing Docker Image to Monitor ***"

docker run --rm --detach --name ${CONTAINER_NAME} ${DOCKER_IMAGE}