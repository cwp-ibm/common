SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
source ${SCRIPT_FOLDER}/utils.sh

DEFAULT_PENDING_ANALYSIS_FOLDER="/data/pending/analysis"

function usage()
{
    echo -n "
    Upload Pending Sysflow analysis results to Virus Total (VT) and save VT hash Id to git repository.

    Usage:
      ./create_pending_analysis.sh [--pending-upload-folder <PU_FOLDER>] [--virus-total-folder <VT_FOLDER>]

    Options:
        --help                                                      Show this screen
        --malwares-containing-folder <MALWARES_CONTAINING_FOLDER>   The path of the folder containing the malwares to generate pending analysis for.
        --pending-analysis-folder <PENDING_ANALYSIS_FOLDER>         [optional] The path to Git VT Hash ids repository.
                                                                    Default: /data/pending/analysis
        --malware-files <MALWARE_FILES>                             [optional] List of specific files in <MALWARES_CONTAINING_FOLDER> to create pending analysis.
                                                                    If not specified will generate pending analysis for all files in <MALWARES_CONTAINING_FOLDER> 
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
            --malwares-containing-folder)
            MALWARES_CONTAINING_FOLDER="$2"
            shift 2
            ;;
			      --pending-analysis-folder )
            PENDING_ANALYSIS_FOLDER="$2"
            shift 2
            ;;
            --malware-files)
            MALWARE_FILES="$2"
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

PENDING_ANALYSIS_FOLDER=${PENDING_ANALYSIS_FOLDER:-DEFAULT_PENDING_ANALYSIS_FOLDER}

if [ ! -d ${PENDING_ANALYSIS_FOLDER} ];
then
  mkdir --parent ${PENDING_ANALYSIS_FOLDER}
  exit_on_error $? "mkdir --parent ${PENDING_ANALYSIS_FOLDER}"
fi

if [ -n "${MALWARE_FILES}" ];
then
  MALWARE_FILES=(${MALWARE_FILES//;/ })
else
  MALWARE_FILES=($(ls ${MALWARES_CONTAINING_FOLDER}))
fi

CURRENT_TIME=$(date +%Y-%m-%dT%H-%M-%S)

for ITEM in "${MALWARE_FILES[@]}"
do
  OUTPUT_FOLDER_FULLPATH="$(readlink -f ${MALWARES_CONTAINING_FOLDER})/${ITEM}"
  ln --symbolic ${OUTPUT_FOLDER_FULLPATH} ${PENDING_ANALYSIS_FOLDER}/${ITEM}_${CURRENT_TIME}
done