#!/usr/bin/env bash


function generate_context() {
    username=$1
    password=$2
    url=$3
    env_type=$4
    cluster_version=$5

    mkdir -p "${env_type}_${cluster_version}"

    KUBECONFIG=${env_type}_${cluster_version}/kubeconfig oc login -u $username -p $password $url
}