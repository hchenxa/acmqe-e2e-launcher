#!/usr/bin/env bash

export DOCKER=${DOCKER:-podman}

function setup_container_client() {
    command -v $DOCKER 2>/dev/null
    if [[ $? -ne 0 ]]; then
        
}

function setup_jq() {
    echo "setup the jq here"
}