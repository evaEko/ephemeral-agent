#!/bin/bash
SERVICE_CONNECTION_ID=$1
PROJECT_ID=$2
ORG_URI=$3
PAT=$4
CURRENT_PIPELINE_ID=$5

# REST API URL for service connection security
URL="$ORG_URI/$PROJECT_ID/_apis/pipelines/pipelinePermissions/endpoint/$SERVICE_CONNECTION_ID?api-version=7.1-preview.1"

# JSON body to update the permissions to the registry service connection
BODY="{
  \"allPipelines\": {
    \"authorized\": true
  },
  \"pipelines\": [
    {
      \"pipelineId\": 204,
      \"authorized\": true
    }
  ],
  \"resource\": {
    \"id\": \"$SERVICE_CONNECTION_ID\",
    \"type\": \"endpoint\"
  }
}"

# Curl command to call the REST API
curl -X PATCH $URL \
     -H "Content-Type: application/json" \
     -H "Authorization: Basic $(echo -n ":$PAT" | base64)" \
     -d "$BODY"