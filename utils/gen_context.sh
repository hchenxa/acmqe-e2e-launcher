#!/usr/bin/env bash

function generate_context() {
    # generate the kubeconfig which used to connect to the cluster
    username=$1
    password=$2
    url=$3
    env_type=$4
    if [[ $env_type == "customer" ]]; then
        _hub_conf_path="env_context/${env_type}"
    else
        cluster_version=$5
        _hub_conf_path="env_context/${env_type}_${cluster_version}"
    fi
    mkdir -p ${_hub_conf_path}
    touch ${_hub_conf_path}/kubeconfig
    KUBECONFIG=${_hub_conf_path}/kubeconfig oc login --insecure-skip-tls-verify=true -u $username -p $password $url
    echo "${_hub_conf_path}/kubeconfig"
}

function generate_context_withtoken() {
    ocp_token=$1
    url=$2
    env_type=$3
    if [[ $env_type == "customer" ]]; then
        _hub_conf_path="env_context/${env_type}"
    else
        cluster_version=$4
        _hub_conf_path="env_context/${env_type}_${cluster_version}"
    fi
    mkdir -p ${_hub_conf_path}
    touch ${_hub_conf_path}/kubeconfig
    KUBECONFIG=${_hub_conf_path}/kubeconfig oc login --insecure-skip-tls-verify=true --token=$ocp_token $url
    echo "${_hub_conf_path}/kubeconfig"    
}

function generate_importcluster_context() {
    namespace=$1
    env_type=$2
    if [[ $env_type == "customer" ]]; then
        _imported_conf_path="env_context/customer"
    else
        cluster_version=$3
        _imported_conf_path="env_context/${env_type}_${cluster_version}"
    fi
    mkdir -p ${_imported_conf_path}
    touch ${_imported_conf_path}/imported_kubeconfig
    if [[ $namespace == "local-cluster" ]]; then
        # If the cluster only have local-cluster, copy the hub cluster context as the imported cluster context.
        cp ${_imported_conf_path}/kubeconfig ${_imported_conf_path}/imported_kubeconfig
    else
        secret_name=$(KUBECONFIG=${_imported_conf_path}/kubeconfig oc get secret -n $namespace | awk '{print $1}' | grep "^$namespace.*admin-kubeconfig$")
        if [[ $(uname -s) == "Darwin" ]]; then
            KUBECONFIG=${_imported_conf_path}/kubeconfig oc get secret -n $namespace $secret_name --template={{.data.kubeconfig}} | base64 -D > ${_imported_conf_path}/imported_kubeconfig
        else
            KUBECONFIG=${_imported_conf_path}/kubeconfig oc get secret -n $namespace $secret_name --template={{.data.kubeconfig}} | base64 -d > ${_imported_conf_path}/imported_kubeconfig
        fi
        echo "apiVersion: v1" >> ${_imported_conf_path}/imported_kubeconfig
    fi
    echo -n "$namespace" > ${_imported_conf_path}/managed_cluster_name
    echo "${_imported_conf_path}/imported_kubeconfig"
}

function generate_options() {

    config_path=$1
    baseDomain=$2
    test_type=$3
    username=$4
    password=$5
    id_provider=$6

    echo "Generate the options.yaml for ${test_type}"
    mkdir -p $config_path/${test_type}

    case $test_type in
        "SEARCH")
            cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  hub:
    baseDomain: $baseDomain
    user: $username
    password: $password
EOF
            ;;
        "KUI")
            cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  hub:
    baseDomain: $baseDomain
    user: $username
    password: $password
EOF
            ;;
        "OBSERVABILITY")
            mkdir -p ${config_path}/${test_type}/resources
            cat << EOF > ${config_path}/${test_type}/resources/options.yaml
options:
  hub:
    baseDomain: $baseDomain
EOF
            ;;
        "GRC_UI")
            cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  hub:
    hubClusterURL: https://api.${baseDomain}:6443
    user: $username
    password: $password
    baseURL: https://multicloud-console.apps.${baseDomain}
EOF
            ;;
    esac
}