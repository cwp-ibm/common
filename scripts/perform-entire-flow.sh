#!/bin/bash

SCRIPT_FOLDER=$(dirname $(readlink -f "$0"))

${SCRIPT_FOLDER}/download-malware-from-vt-handler.sh 
${SCRIPT_FOLDER}/perform-pending-analysis.sh
${SCRIPT_FOLDER}/upload-pending.sh