#!/usr/bin/env bash

# The function get_mco_cr return if the cluster have MCO enabled or not.
function get_mco_cr() {

    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _hub_conf_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _hub_conf_path="env-context/${_cluster_type}-${_cluster_version}"
    fi
    
    if [[ $(KUBECONFIG="${_hub_conf_path}/kubeconfig" oc get mco --no-headers | wc -l |  sed 's/^ *//') == '0' ]]; then
        echo "false"
    else
        echo "true"
    fi

}