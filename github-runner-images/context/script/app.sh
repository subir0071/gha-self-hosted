#!/bin/bash

pip3 install -r requirements.txt
runner_token=$(python3 generate_jwt.py)

 ./config.sh --url https://github.com/gha-runner \
                --token runner_token \
                --name $encoded_jwt \
                --labels linux,x86_64,test \
                --unattended \
                --work /opt/github/actions-runner

./run.sh