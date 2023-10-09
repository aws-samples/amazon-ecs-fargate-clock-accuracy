#
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
#!/usr/bin/env sh

# Variables
TASK_DETAILS=$(wget -qO- "${ECS_CONTAINER_METADATA_URI_V4}/task")
CLOCK_ERROR_BOUND=$(echo "${TASK_DETAILS}" | jq -r '.ClockDrift.ClockErrorBound')
REFERENCE_TIMESTAMP=$(echo "${TASK_DETAILS}" | jq -r '.ClockDrift.ReferenceTimestamp')
CLOCK_SYNCHRONIZATION_STATUS=$(echo "${TASK_DETAILS}" | jq -r '.ClockDrift.ClockSynchronizationStatus')
CLUSTER=$(echo "${TASK_DETAILS}" | jq -r '.Cluster' | awk -F '/' '{print $NF}')
SERVICE_NAME=$(echo "${TASK_DETAILS}" | jq -r '.ServiceName')
FAMILY=$(echo "${TASK_DETAILS}" | jq -r '.Family')
TASK_ID=$(echo "${TASK_DETAILS}" | jq -r '.TaskARN' | awk -F '/' '{print $NF}')

# Log prints
printf "[STARTING] ----- %s\n" "$(date)"
printf "Task details - %s : %s : %s\n" "$CLUSTER" "$SERVICE_NAME" "$TASK_ID"
printf "Clock error bound - %s\n" "$CLOCK_ERROR_BOUND"
printf "Reference Timestamp - %s\n" "$REFERENCE_TIMESTAMP"
printf "Clock synchronisation status - %s\n" "$CLOCK_SYNCHRONIZATION_STATUS"

## Create or update a custom metric in CW
# The namespaces will be decided depending on if this is a single Task or a Service
#
# NOTE - For now 'ServiceName' is not available in Fargate, hence it is not possible to generate a
# Service namespace. This is kept for further use.

if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "null" ]; then

    printf "Adding metrics...\n"
    aws cloudwatch put-metric-data --metric-name ClockErrorBound \
                                   --dimensions ClusterName="${CLUSTER}",Family="${FAMILY}",TaskID="${TASK_ID}" \
                                   --namespace "ECS/ContainerInsights" \
                                   --value "${CLOCK_ERROR_BOUND}"

else

    printf "Adding metrics as part of service: %s\n" "$SERVICE_NAME"
    aws cloudwatch put-metric-data --metric-name ClockErrorBound \
                                   --dimensions ClusterName="${CLUSTER}",ServiceName="${SERVICE_NAME}",TaskID="${TASK_ID}" \
                                   --namespace "ECS/ContainerInsights" \
                                   --value "${CLOCK_ERROR_BOUND}"

fi

printf "[DONE] - %s" "$(date)\n"