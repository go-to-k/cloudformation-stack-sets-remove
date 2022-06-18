#!/bin/bash
set -eu

cd $(dirname $0)
. ./stack_sets_functions.sh

PROFILE=""

while getopts p: OPT; do
    case $OPT in
        p)
            PROFILE="$OPTARG"
            ;;
    esac
done

if [ -z ${PROFILE} ]; then
    echo "required PROFILE"
    exit 1
fi

CFN_STACK_SET_NAME="SNSForStacksets"
OPERATION_REGION="us-east-1"

delete_stack_sets "${CFN_STACK_SET_NAME}" "${OPERATION_REGION}" "${PROFILE}" 