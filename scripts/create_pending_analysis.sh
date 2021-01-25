#!/bin/bash
SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))
source ${SCRIPT_FOLDER}/utils.sh

function usage()
{
    echo -n "
    Creates symbolic links in <PENDING_ANALYSIS_FOLDER> to malwares pending to being analyzed.

    Usage:
      ./create_pending_analysis.sh --malwares-containing-folder <MALWARES_CONTAINING_FOLDER> 
                                  [--pending-analysis-folder <PENDING_ANALYSIS_FOLDER>] 
                                  [--malware-files <MALWARE_FILES>]

    Options:
        --help                                                              Show this screen
        --malwares-containing-folder <MALWARES_CONTAINING_FOLDER>           The path of the folder containing the malwares to generate pending analysis for.
        --pending-analysis-folder <PENDING_ANALYSIS_FOLDER>                 [optional] The path to create the pending analysis symbolic links.
                                                                            Default: $DEFAULT_BASE_PENDING_ANALYSIS_FOLDER
        --malware-files <MALWARE_FILES>                                     [optional] List of specific files in <MALWARES_CONTAINING_FOLDER> to create pending analysis.
                                                                            If not specified will generate pending analysis for all files in <MALWARES_CONTAINING_FOLDER> 
        --pending-analysis-relative-path <PENDING_ANALYSIS_RELATIVE_PATH>   [optional]
                                                                            Defaults to empty string
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
			      --pending-analysis-folder)
            PENDING_ANALYSIS_FOLDER="$2"
            shift 2
            ;;
            --malware-files)
            MALWARE_FILES="$2"
            shift 2
            ;;
            --pending-analysis-relative-path) 
            PENDING_ANALYSIS_RELATIVE_PATH="$2"
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

function main()
{
  parse_args "$@"
  PENDING_ANALYSIS_FOLDER=${PENDING_ANALYSIS_FOLDER:-$DEFAULT_BASE_PENDING_ANALYSIS_FOLDER}
  PENDING_ANALYSIS_RELATIVE_PATH=${PENDING_ANALYSIS_RELATIVE_PATH:-""}
  create_directory ${PENDING_ANALYSIS_FOLDER}
  if [ -n "${MALWARE_FILES}" ];
  then
    MALWARE_FILES=(${MALWARE_FILES//;/ })
  else
    MALWARE_FILES=($(ls ${MALWARES_CONTAINING_FOLDER} -I *.Dockerfile))
  fi
  for ITEM in "${MALWARE_FILES[@]}"
  do
    OUTPUT_FOLDER_FULLPATH="$(readlink -f ${MALWARES_CONTAINING_FOLDER})/${ITEM}"
    SYMBOLIC_LINK_FILE=${PENDING_ANALYSIS_FOLDER}/${PENDING_ANALYSIS_RELATIVE_PATH}/${ITEM}
    create_directory ${PENDING_ANALYSIS_FOLDER}/${PENDING_ANALYSIS_RELATIVE_PATH}
    if [ ! -L ${SYMBOLIC_LINK_FILE} ]
    then
      log "Creating symbolic link for ${OUTPUT_FOLDER_FULLPATH}" 
      ln --symbolic ${OUTPUT_FOLDER_FULLPATH} ${SYMBOLIC_LINK_FILE}
    else
      log "Symbolic link for ${OUTPUT_FOLDER_FULLPATH} already exists" 
    fi
  done
}

main "$@"
