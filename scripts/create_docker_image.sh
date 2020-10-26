#!/bin/bash
echo ""
DEFAULT_BASE_IMAGE=ubuntu:20.04
BASE_IMAGE=${DEFAULT_BASE_IMAGE}
CONTEXT=
EXECUTABLE=
OVERRIDE=false

function usage()
{
    echo -n "
    Create Docker image to run executable

    Usage:
      ./create_docker_image.sh --context <CONTEXT> --executable <EXECUTABLE> [--base-image <BASE IMAGE>] [--force]

    Options:
      --help                        Show this screen
      --context <CONTEXT>           Set the docker context 
      --executable <EXECUTABLE>     Set the executable to be run 
      --base-image <BASE IMAGE>     Set the base image in which the <EXECUTABLE> will be run in.
                                    If not defined defaults to ubuntu:20.04
      --force                       override previous generated Dockerfile in context
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
            --context)
            CONTEXT="$2"
            if [ ! -d "$CONTEXT" ]; then
                echo "Error: --context value does not exist or is an invalid directory" >&2
                usage
                exit 1
            fi
            shift 2
            ;;
            --executable)
            EXECUTABLE="$2"
            shift 2
            ;;
            --base-image)
            BASE_IMAGE="$2"
            shift 2
            ;;
            --force)
            OVERRIDE=true
            shift 
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

IMAGE_TAG="$(basename ${EXECUTABLE})":"${BASE_IMAGE/:/_}"

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))

if [[ ! -f "${CONTEXT}/Dockerfile" ]] || [[ "${OVERRIDE}" == true ]]; then
    sed -n "s/BASE_IMAGE/${BASE_IMAGE}/g;s/EXECUTABLE/${EXECUTABLE}/g;w ${SCRIPT_FOLDER}/Dockerfile" ${SCRIPT_FOLDER}/Dockerfile.template
    mv ${SCRIPT_FOLDER}/Dockerfile "${CONTEXT}"
fi

docker build --tag "${IMAGE_TAG}" "${CONTEXT}"