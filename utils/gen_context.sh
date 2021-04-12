#!/usr/bin/env bash

function generate_context() {
    username=$1
    password=$2
    url=$3
    env_type=$4
    cluster_version=$5

    mkdir -p env_context/${env_type}_${cluster_version}
    touch env_context/${env_type}_${cluster_version}/kubeconfig

    KUBECONFIG=env_context/${env_type}_${cluster_version}/kubeconfig oc login --insecure-skip-tls-verify=true -u $username -p $password $url
    # return KUBECONFIG
}
