#!/usr/bin/env bash

export DOCKER=${DOCKER:-docker}

function setup_container_client() {
    command -v $DOCKER 2>/dev/null
    if [[ $? -ne 0 ]]; then
       if [[ $DOCKER == "docker" ]]; then
          sudo dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
          sudo dnf install -y docker-ce
          sudo systemctl enable docker --now
          sudo systemctl restart docker
       else
          sudo dnf install -y $DOCKER
       fi 
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
    chmod +x ./jq && sudo mv ./jq /usr/local/bin/
   fi
}

function setup_oc() {
    command -v oc 2> /dev/null
    if [[ $? -ne 0 ]]; then
        curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
        sudo tar -zxf openshift-client-linux.tar.gz -C /usr/local/bin
        sudo chmod a+x /usr/local/bin/oc
    fi
}

function install_python_dep() {
    # Need to make sure the python was installed.
    command -v python3 2>/dev/null
    if [[ $? -ne 0 ]]; then
        sudo dnf install -y python3 python3-pip
    fi
    sudo pip3 install untangle &> /dev/null
}