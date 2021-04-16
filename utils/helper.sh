#!/usr/bin/env bash

function get_supported_type() {
    acm_version=$1
    supported_type=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[].type" config/environment.json)
    return $supported_type
}

function get_ocp_route() {
    cluster_type=$1
    acm_version=$2
    return ocp_version=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|ocp_route" config/environment.json)
}

function get_acm_route() {
    cluster_type=$1
    acm_version=$2
    return acm_version=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|acm_route" config/environment.json)   
}

function phase_version() {
    old_version=$1
    echo $old_version|awk -F '.' '{print $1$2}'
}

function phase_type() {
    # Used to translet the type to upper.
    old_type=$*
    echo $old_type|tr 'a-z' 'A-Z'
}

function get_basedomain() {
    # Used to get the cluster base domain
    cluster_type=$1
    acm_version=$2
    route_console=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get route -n openshift-console console -o jsonpath={.spec.host})
    echo ${route_console#*apps.}
}

function get_idprovider() {
    cluster_type=$1
    acm_version=$2
    echo $(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc whoami)
}

function check_imported_cluster() {
    cluster_type=$1
    acm_version=$2
    cluster_namespace=$3
    if [[ $(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get clusterdeployment -n $cluster_namespace | wc -l | sed 's/^ *//') == 0 ]]; then
        # If no clusterdeployment exists in the namespace, that means the cluster was imported.
        echo "false"
    else
        # If there have clusterdeployment exists in the namespace, that means the cluster was created by hive.
        echo "true"
    fi
}