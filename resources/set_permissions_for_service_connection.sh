#!/bin/bash
SERVICE_CONNECTION=$1
PROJECT_NAME=$2
ORG_URI=$3
PAT=$4

# Corrected variable usage for the endpoint URL
URL_ENDPOINT="$ORG_URI/$PROJECT_NAME/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"

# Use the correct variable and quote it to handle special characters
endpoints=$(curl -X GET "$URL_ENDPOINT" \
     -H "Content-Type: application/json" \
     -H "Authorization: Basic $(echo -n ":$PAT" | base64)")

# Check for curl errors
if [ $? -ne 0 ]; then
    echo "Error fetching endpoints"
    exit 1
fi

# Parse the endpoint ID and check for jq errors
service_endpoint_id=$(echo $endpoints | jq -r '.value[] | select(.name=="'$SERVICE_CONNECTION'") | .id')
if [ $? -ne 0 ]; then
    echo "Error parsing endpoint ID"
    exit 1
fi

# Check if the service_endpoint_id is empty
if [ -z "$service_endpoint_id" ]; then
    echo "Service Endpoint ID not found"
    exit 1
fi

# Use the parsed service endpoint ID to construct the permissions URL
URL="$ORG_URI/$PROJECT_NAME/_apis/pipelines/pipelinePermissions/endpoint/$service_endpoint_id?api-version=7.1-preview.1"

# Define the JSON body for setting permissions
BODY="{
  \"allPipelines\": {
    \"authorized\": true 
  },
  \"resource\": {
    \"id\": \"$service_endpoint_id\",
    \"type\": \"endpoint\"
  }
}"

# Execute the PATCH request to update permissions and check for curl errors
curl -X PATCH "$URL" \
     -H "Content-Type: application/json" \
     -H "Authorization: Basic $(echo -n ":$PAT" | base64)" \
     -d "$BODY"

if [ $? -ne 0 ]; then
    echo "Error setting permissions"
    exit 1
fi
