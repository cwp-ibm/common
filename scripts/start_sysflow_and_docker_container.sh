#!/bin/bash

function usage()
{
    echo -n "
    Start Sysflow and a Docker image to monitor. 

    Usage:
      ./start_sysflow_and_docker_container.sh --docker-image <DOCKER-IMAGE>

    Options:
      --help                            Show this screen
      --docker-image <DOCKER-IMAGE>     The Docker image to run 
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
            --docker-image)
            DOCKER_IMAGE="$2"
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

parse_args "$@"

HOSTNAME=local

DOCKER_IMAGE_FOLDER=${DOCKER_IMAGE/:/_}

CONTAINER_NAME=${DOCKER_IMAGE/:/_}

CURRENT_TIME=$(date +%Y-%m-%dT%H-%M-%S)

SYSFLOW_OUTPUT_FOLDER=${HOME}/SysFlow/out/${DOCKER_IMAGE_FOLDER}/${CURRENT_TIME}

mkdir --parents ${SYSFLOW_OUTPUT_FOLDER}

# The location of Sysflow's output
LOCALHOST_VOLUME=${SYSFLOW_OUTPUT_FOLDER}

SYSFLOW_CONTAINER_NAME="sf-collector.${DOCKER_IMAGE//[:_]/-}"

echo "*** Initializing SysFlow Collector ***"

docker run \
	--name "${SYSFLOW_CONTAINER_NAME}" \
	--privileged \
	--rm \
	--detach \
	-v /var/run/docker.sock:/host/var/run/docker.sock \
	-v /dev:/host/dev \
	-v /proc:/host/proc:ro \
	-v /boot:/host/boot:ro \
	-v /lib/modules:/host/lib/modules:ro \
	-v /usr:/host/usr:ro \
	-v ${LOCALHOST_VOLUME}:/mnt/data \
	-e EXPORTER_ID=${HOSTNAME} \
	-e OUTPUT=/mnt/data/test_scenario \
	-e FILTER="container.name!=${SYSFLOW_CONTAINER_NAME} and container.name=${CONTAINER_NAME}" \
	-e INTERVAL=600 \
	 sysflowtelemetry/sf-collector:latest

echo "*** Waiting 10 seconds before Initializing Docker Image ***"

sleep 10

echo "*** Initializing Docker Image to Monitor ***"

docker run --rm --detach --name ${CONTAINER_NAME} ${DOCKER_IMAGE}