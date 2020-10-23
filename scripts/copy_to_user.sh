if [[ "$#" -ne 4 ]]; then
  echo "You must enter exactly 4 command line arguments"
  echo "specify --account ACCOUNT and --source SOURCE"
  exit
fi

if [[ "$1" == "--account" ]]; then
  ACCOUNT=$2
elif [[ "$3" == "--account" ]]; then
  ACCOUNT=$4
fi

if [[ "$1" == "--source" ]]; then
  SOURCE=$2
elif [[ "$3" == "--source" ]]; then
  SOURCE=$4
fi

DESTINATION=/home/${ACCOUNT}

if [[ -d ${SOURCE} ]]; then
  CP_PARAMS=-r
fi

sudo cp -r ${SOURCE} ${DESTINATION}

if [[ -f ${SOURCE} ]]; then
  SOURCE=$(basename ${SOURCE})
fi

sudo chown -R ${ACCOUNT}:${ACCOUNT} ${DESTINATION}/${SOURCE}
