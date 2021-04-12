#!/usr/bin/env bash

export DOCKER=${DOCKER:-podman}

function setup_container_client() {
    command -v $DOCKER 2>/dev/null
    if [[ $? -ne 0 ]]; then
        dnf install -y $DOCKER
    fi
}

function setup_jq() {
    echo "setup the jq here"
}

function setup_oc {
    command -v oc 2> /dev/null
    if [[ $? -ne 0 ]]; then
        curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
        tar xvf openshift-client-linux.tar.gz
    fi
}