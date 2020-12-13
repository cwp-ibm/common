#!/bin/bash

function usage()
{
    echo -n "
    Start Sysflow monitor. 

    Usage:
      ./run_docker_image_for_user.sh --user <USER> --docker-image <DOCKER-IMAGE> --duration <DURATION>

    Options:
      --help                            Show this screen
      --user <USER>                     Run docker as USER
      --docker-image <DOCKER-IMAGE>     The Docker image to run 
      --duration <DURATION>	            The duration in seconds before stoping the docker container
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
            --user)
            USER="$2"
            shift 2
            ;;
            --docker-image)
            DOCKER_IMAGE="$2"
            shift 2
            ;;
			--duration)
            DURATION="$2"
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

su - $USER -c "docker run --stop-timeout $DURATION --name $CONTAINER_NAME $DOCKER_IMAGE"

export CONTAINER_NAME