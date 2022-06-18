#!/bin/bash
set -eu

function check_stack_set_operation {
    local stack_set_name="$1"
    local operation_id="$2"
    local operation_region="$3"
    local profile="$4"

    if [ -z ${stack_set_name} ] \
        || [ -z ${operation_id} ] \
        || [ -z ${operation_region} ] \
        || [ -z ${profile} ]; then
        echo "Invalid options for check_stack_set_operation function"
        return 1
    fi

    while true;
    do
        local operation_status=$(aws cloudformation describe-stack-set-operation \
            --stack-set-name ${stack_set_name} \
            --operation-id ${operation_id} \
            --region ${operation_region} \
            --profile ${profile} \
            | jq -r .StackSetOperation.Status)

        echo "=== STATUS: ${operation_status} ==="

        if [ "${operation_status}" == "RUNNING" ]; then
            echo "Waiting for SUCCEEDED..."
            echo
            sleep 10
        elif [ "${operation_status}" == "SUCCEEDED" ]; then
            echo "SUCCESS."
            break
        else
            echo "!!!!!!!!!!!!!!!!!!!!!!!"
            echo "!!! Error Occurred. !!!"
            echo "!!!!!!!!!!!!!!!!!!!!!!!"
            return 1
        fi
    done
}

function delete_stack_sets {
    local stack_set_name="$1"
    local operation_region="$2"
    local profile="$3"

    if [ -z "${stack_set_name}" ] \
    || [ -z "${operation_region}" ] \
    || [ -z "${stack_set_type}" ] \
    || [ -z "${profile}" ]; then
        echo "Invalid options for delete_stack_sets function"
        return 1
    fi

    check_stack_exists=$(aws cloudformation describe-stack-set \
        --stack-set-name ${stack_set_name} \
        --region ${operation_region} \
        --profile ${profile} 2>&1 >/dev/null || true)

    if [ -n "${check_stack_exists}" ]; then
        echo "not exists stack sets!"
        echo
        return 1
    else
        stack_instances_regions=$(aws cloudformation list-stack-instances \
            --stack-set-name ${stack_set_name} \
            --region ${operation_region} \
            --query "Summaries[].Region" \
            --output text \
            --profile ${profile} \
            2>/dev/null \
            | sed -e "s/\t/ /g" \
            || true \
        )

        account_id=$(aws sts get-caller-identity --query "Account" --output text --profile ${profile})

        echo "delete stack instances..."
        echo

        operation_id=$(aws cloudformation delete-stack-instances \
            --stack-set-name ${stack_set_name} \
            --accounts ${account_id} \
            --regions ${stack_instances_regions} \
            --no-retain-stacks \
            --operation-preferences MaxConcurrentCount=1 \
            --region ${operation_region} \
            --query "OperationId" \
            --output text \
            --profile ${profile})
            
        check_stack_set_operation "${stack_set_name}" "${operation_id}" "${operation_region}" "${profile}"

        echo "delete stack sets..."
        echo

        aws cloudformation delete-stack-set \
            --stack-set-name ${stack_set_name} \
            --region ${operation_region} \
            --query "OperationId" \
            --output text \
            --profile ${profile}
    fi

    echo "Finished."
}