#!/bin/bash

function usage()
{
    echo -n "
    Stop Sysflow and the Docker container. 

    Usage:
      ./stop_sysflow_and_docker_container.sh --docker-image <DOCKER-IMAGE>

    Options:
      --help                  			Show this screen
	  --docker-image <DOCKER-IMAGE> 	The Docker image used to start the container 
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

CONTAINER_NAME=${DOCKER_IMAGE/:/_}

echo "*** Stoping Target Docker ***"

docker container stop ${CONTAINER_NAME}

echo "*** Waiting 10 seconds before Stoping SysFlow Collector ***"

sleep 10

echo "*** Stoping SysFlow Collector ***"

SYSFLOW_CONTAINER_NAME="sf-collector.${DOCKER_IMAGE//[:_]/-}"

docker container stop "${SYSFLOW_CONTAINER_NAME}"
