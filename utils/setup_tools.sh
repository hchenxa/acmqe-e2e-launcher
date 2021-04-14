#!/usr/bin/env bash

export DOCKER=${DOCKER:-docker}

function setup_container_client() {
    command -v $DOCKER 2>/dev/null
    if [[ $? -ne 0 ]]; then
        dnf install -y $DOCKER
    fi
}

function setup_jq() {
    command -v jq &> /dev/null
    if [[ $? -ne 0 ]]; then
     if [[ "$(uname)" == "Darwin" ]]; then
        curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
     elif [[ "$(uname)" == "Linux" ]]; then
        curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
     fi
    chmod +x ./jq && mv ./jq /usr/local/bin/
   fi
}

function setup_oc {
    command -v oc 2> /dev/null
    if [[ $? -ne 0 ]]; then
        curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
        tar xvf openshift-client-linux.tar.gz
    fi
}
