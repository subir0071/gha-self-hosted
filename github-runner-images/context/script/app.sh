#!/bin/bash

# #######################################################################
# This shell script registers the self hosted runner with a specific 
# github organization.
# This script would need the below environment variable to be available :
# PEM_CONTENT :: The content of the Github App PEM file.
# GH_CLIENT_ID :: Client ID of the Github APP
# GH_APP_INSTT_ID :: Installation ID of the Github App
# GH_ORG_NAME : Github Organisation Name
# #######################################################################

pip3 install -r requirements.txt
runner_token=$(python3 generate_jwt.py)
export RUNNER_ALLOW_RUNASROOT=1

installation_token=$(curl -X POST \
     -H "Authorization: Bearer $runner_token" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/app/installations/$GH_APP_INSTT_ID/access_tokens | jq -r '.token')

registration_token=$(curl --request POST \
--url "https://api.github.com/orgs/$GH_ORG_NAME/actions/runners/registration-token" \
--header "Authorization: Bearer $installation_token" \
--header "X-GitHub-Api-Version: 2022-11-28" | jq -r '.token')

 ./config.sh --url https://github.com/$GH_ORG_NAME \
                --token $registration_token \
                --name $(cat /proc/self/cgroup | grep "cpu:" | awk -F/ '{print $NF}') \
                --labels linux,x86_64,test \
                --unattended \
                --ephemeral

./run.sh