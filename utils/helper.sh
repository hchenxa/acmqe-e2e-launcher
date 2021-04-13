#!/usr/bin/env bash

function get_supported_type() {
    acm_version=$1
    supported_type=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[].type" config/environment.json)
    return $supported_type
}

function get_ocp_route() {
    acm_version=$1
    cluster_type=$2
    return ocp_version=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|ocp_route" config/environment.json)
}

function get_acm_route() {
    acm_version=$1
    cluster_type=$2
    return acm_version=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|acm_route" config/environment.json)   
}

function phase_version() {
    old_version=$1
    echo $old_version|awk -F '.' '{print $1$2}'
}

function phase_type() {
    # Used to translet the type to upper.
    old_type=$1
    echo $old_type|tr 'a-z' 'A-Z'
}