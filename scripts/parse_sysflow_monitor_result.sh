#!/bin/bash

# The SysFlow output folder (Full Path)
LOCALHOST_VOLUME=$1

echo "*** Running SysPrint ***"

docker run \
    --rm \
    -v ${LOCALHOST_VOLUME}:/mnt/data \
    sysflowtelemetry/sysprint -o json -w /mnt/data/test_scenario /mnt/data

echo "*** Pretifying output for human readability  ***"

jq . ${LOCALHOST_VOLUME}/test_scenario > ${LOCALHOST_VOLUME}/test_scenario.json