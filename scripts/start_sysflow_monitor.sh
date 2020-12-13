#!/bin/bash

function usage()
{
    echo -n "
    Start Sysflow monitor. 

    Usage:
      ./start_sysflow_monitor.sh --docker-image <DOCKER-IMAGE> --output-folder <OUTPUT-FOLDER>

    Options:
      --help                            Show this screen
      --docker-image <DOCKER-IMAGE>     The Docker image to run 
      --output-folder <OUTPUT-FOLDER>	The folder to save the Sysflow output
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
			--output-folder)
            OUTPUT_FOLDER="$2"
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

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))

source ${SCRIPT_FOLDER}/utils.sh

generate_container_name $DOCKER_IMAGE

HOSTNAME=local

CURRENT_TIME=$(date +%Y-%m-%dT%H-%M-%S)

SYSFLOW_OUTPUT_FOLDER=${OUTPUT_FOLDER}/SysFlow_Analysis_Outputs/${CURRENT_TIME}

mkdir --parents ${SYSFLOW_OUTPUT_FOLDER}

# The location of Sysflow's output
LOCALHOST_VOLUME=${SYSFLOW_OUTPUT_FOLDER}

SYSFLOW_CONTAINER_NAME="sf-collector.${DOCKER_IMAGE//[:_]/-}"

echo "*** Initializing SysFlow Collector ***"

docker run \
	-t \
	-i \
	--detach \
	--privileged \
	--name "${SYSFLOW_CONTAINER_NAME}" \
	-v /var/run/docker.sock:/host/var/run/docker.sock \
	-v /dev:/host/dev \
	-v /proc:/host/proc:ro \
	-v /boot:/host/boot:ro \
	-v /lib/modules:/host/lib/modules:ro \
	-v /usr:/host/usr:ro \
	-v ${LOCALHOST_VOLUME}:${SYSFLOW_CONTAINER_OUTPUT_PATH} \
	-e EXPORTER_ID=${HOSTNAME} \
	-e OUTPUT=${SYSFLOW_CONTAINER_OUTPUT_PATH}/${SYSFLOW_CONTAINER_OUTPUT_FILENAME} \
	-e FILTER="container.name!=${SYSFLOW_CONTAINER_NAME} and container.name=${CONTAINER_NAME}" \
	-e INTERVAL=600 \
	--rm \
	 sysflowtelemetry/sf-collector:edge

export SYSFLOW_OUTPUT_FOLDER