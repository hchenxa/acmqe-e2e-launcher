#!/usr/bin/env bash

function get_supported_type() {
    acm_version=$1
    supported_type=$(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[].type" config/environment.json)
    return $supported_type
}

function get_ocp_route_from_file() {
    # Used to get the ocp route address from the file
    cluster_type=$1
    acm_version=$2
    echo $(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|ocp_route" config/environment.json)
}

function get_acm_route_from_file() {
    # Used to get the acm route address from the file
    cluster_type=$1
    acm_version=$2
    echo $(jq -r ".acm_versions[]|select(.version == $acm_version)|.envs[]|select(.type== "$cluster_type")|acm_route" config/environment.json)   
}

function get_acm_version() {
    # Used to get the acm version
    cluster_type=$1
    if [[ $cluster_type == "customer" ]]; then
        acm_package=$(KUBECONFIG=env_context/customer/kubeconfig oc get csv --all-namespaces | grep advanced-cluster-management | awk '{print $2}')
    else
        acm_version=$2
        acm_package=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get csv --all-namespaces | grep advanced-cluster-management | awk '{print $2}')
    fi
    echo ${acm_package#*advanced-cluster-management.}
}

function get_acm_console() {
    # Used to get the acm console
    cluster_type=$1
    if [[ $cluster_type == "customer" ]]; then
        acm_console=$(KUBECONFIG=env_context/customer/kubeconfig oc get route --all-namespaces | grep multicloud-console | awk '{print $3}')
    else
        acm_version=$2
        acm_console=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get route --all-namespaces | grep multicloud-console | awk '{print $3}')
    fi
    echo ${acm_console}
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
    if [[ $cluster_type == "customer" ]]; then
        route_console=$(KUBECONFIG=env_context/customer/kubeconfig oc get route -n openshift-console console -o jsonpath={.spec.host})
    else
        acm_version=$2
        route_console=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get route -n openshift-console console -o jsonpath={.spec.host})
    fi
    echo ${route_console#*apps.}
}

function get_acm_route() {
    # Used to get the acm route
    cluster_type=$1

    # We may not know the acm installed namespace, so need to filter out the namespace first all get the route from all namespaces.
    if [[ $cluster_type == "customer" ]]; then
        _acm_installed_namespace=$(KUBECONFIG=env_context/customer/kubeconfig oc get subscriptions.operators.coreos.com --all-namespaces | grep advanced-cluster-management | awk '{print $1}')
        route_console=$(KUBECONFIG=env_context/customer/kubeconfig oc get route multicloud-console -n $_acm_installed_namespace -o=jsonpath='{.spec.host}')
    else
        acm_version=$2
        _acm_installed_namespace=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get subscriptions.operators.coreos.com --all-namespaces | grep advanced-cluster-management | awk '{print $1}')
        route_console=$(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc get route multicloud-console -n $_acm_installed_namespace -o=jsonpath='{.spec.host}')
    fi
    echo ${route_console}
}

function get_idprovider() {
    cluster_type=$1
    if [[ $cluster_type == "customer" ]]; then
        echo $(KUBECONFIG=env_context/customer/kubeconfig oc whoami)
    else
        acm_version=$2
        echo $(KUBECONFIG=env_context/${cluster_type}_${acm_version}/kubeconfig oc whoami)
    fi
}

function check_imported_cluster() {
    kubeconfig_path=$1
    cluster_namespace=$2
    if [[ $(KUBECONFIG=$kubeconfig_path oc get clusterdeployment -n $cluster_namespace | wc -l | sed 's/^ *//') == 0 ]]; then
        # If no clusterdeployment exists in the namespace, that means the cluster was imported.
        echo "false"
    else
        # If there have clusterdeployment exists in the namespace, that means the cluster was created by hive.
        echo "true"
    fi
}

function get_imported_cluster() {
    kubeconfig_path=$1
    _managed_cluster=$(KUBECONFIG=$kubeconfig_path oc get managedcluster --no-headers --ignore-not-found | awk '{print $1}')
    if [[ $(echo "$_managed_cluster" | wc -l | sed 's/\ //g' ) == 0 ]]; then
        echo ""
    elif [[ $(echo "$_managed_cluster" | wc -l | sed 's/\ //g' ) == 1 ]]; then
        if [[ $_managed_cluster == "local-cluster" ]]; then
            echo "local-cluster"
        else
            _imported_by_hive=$(check_imported_cluster ${kubeconfig_path} ${_managed_cluster})
            if [[ $_imported_by_hive == 'true' ]]; then
                echo ${_managed_cluster}
            else
                echo ""
            fi
        fi
    else
        _flag=0
        for mc in $_managed_cluster
        do
            if [[ $mc == "local-cluster" ]]; then
                echo "local-cluster"
                break
            else
                # (TODO) Will filter out the unavailable cluster later
                _imported_by_hive=$(check_imported_cluster ${kubeconfig_path} $mc)
                if [[ $_imported_by_hive == 'true' ]]; then
                    echo "$mc"
                    _flag=1
                else
                    continue
                fi
                if [[ $_flag == 1 ]]; then
                    break
                fi
            fi
        done
    fi
}

function get_config_path() {
    cluster_type=$1
    if [[ $cluster_type == "customer" ]]; then
        echo "env_context/customer"
    else
        acm_version=$2
        echo "env_context/${cluster_type}_${acm_version}"
    fi
}