function usage()
{
    echo -n "
    Upload file to Virus Total, persist the returned Hash Id to /data/results and push Hash ID to Github repo. 

    Usage:
      ./create_docker_image.sh --context <CONTEXT> --executable <EXECUTABLE> [--base-image <BASE IMAGE>] [--force]

    Options:
      --help                  Show this screen
      --file <FILE>           The file to upload to Virus Total 
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
            --file)
            FULL_FILE_PATH="$2"
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

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
source ${SCRIPT_FOLDER}/vt-api-key.env

parse_args "$@"

VT_UPLOAD_RESPONSE=$(curl --request POST \
  --url https://www.virustotal.com/api/v3/files \
  --header "x-apikey: ${VT_API_KEY}" \
  --form file=@${FULL_FILE_PATH})

VT_HASH_ID=$(echo $VT_UPLOAD_RESPONSE | jq .data.id )

HASH_ID_FILE_NAME=${VT_HASH_ID//\"/''}

HASH_ID_FILE_PATH=${SCRIPT_FOLDER}/../results/$(date +%Y/%m/%d/%H%M%S)

mkdir --parents ${HASH_ID_FILE_PATH}

touch ${HASH_ID_FILE_PATH}/${HASH_ID_FILE_NAME}

cd ${SCRIPT_FOLDER}/../results

git add .

git commit -m "Add Hash ID for $(basename ${FULL_FILE_PATH})"

git push

cd -
