#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 AGENT_NAME AZ_TOKEN ORG_URL AZ_POOL"
    exit 1
fi

# Assign arguments to variables
ORG_URL=$1
AZ_TOKEN=$2
AZ_POOL=$3
AGENT_NAME=$4

# Encode AZ_TOKEN for use in Basic Auth header
encodedToken=$(echo -n ":$AZ_TOKEN" | base64)

# Get Pool ID
poolsUrl="$ORG_URL/_apis/distributedtask/pools?api-version=7.1-preview.1"
response=$(curl -Lsv -H "Authorization: Basic $encodedToken" "$poolsUrl")
poolId=$(curl -Lsv -H "Authorization: Basic $encodedToken" "$poolsUrl" | jq -r ".value[] | select(.name==\"$AZ_POOL\") | .id")
if [ -z "$poolId" ]; then
    echo "Pool not found"
    exit 1
fi

# Get Agent ID
agentsUrl="$ORG_URL/_apis/distributedtask/pools/$poolId/agents?api-version=7.1-preview.1"
agentId=$(curl -Lsv -H "Authorization: Basic $encodedToken" "$agentsUrl" | jq -r ".value[] | select(.name==\"$AGENT_NAME\") | .id")
echo "Response from agentId"
echo $agentId

if [ -z "$agentId" ]; then
    echo "Agent not found"
    exit 1
fi

# Delete Agent
deleteUrl="$ORG_URL/_apis/distributedtask/pools/$poolId/agents/$agentId?api-version=7.1-preview.1"
curl -Lsv -H "Authorization: Basic $encodedToken" -X DELETE $deleteUrl

echo "Agent deleted successfully"
