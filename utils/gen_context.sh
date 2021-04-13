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

function generate_importcluster_context() {
    namespace=$1
    env_type=$2
    cluster_version=$3
    mkdir -p env_context/${env_type}_${cluster_version}
    touch env_context/${env_type}_${cluster_version}/imported_kubeconfig
    if [[ $namespace == "local-cluster" ]]; then
        # If the cluster only have local-cluster, copy the hub cluster context as the imported cluster context.
        cp env_context/${env_type}_${cluster_version}/kubeconfig env_context/${env_type}_${cluster_version}/imported_kubeconfig
    else
        secret_name=$(KUBECONFIG=env_context/${env_type}_${cluster_version}/kubeconfig oc get secret -n $namespace | awk '{print $1}' | grep "^$namespace.*admin-kubeconfig$")
        KUBECONFIG=env_context/${env_type}_${cluster_version}/kubeconfig oc get secret -n $namespace $secret_name --template={{.data.kubeconfig}} | base64 -D > env_context/${env_type}_${cluster_version}/imported_kubeconfig
        echo "apiVersion: v1" >> env_context/${env_type}_${cluster_version}/imported_kubeconfig
    fi
}

function generate_options() {

    env_type=$1
    cluster_version=$2
    baseDomain=$3

    cat << EOF > env_context/options.yaml
options:
  hub:
    baseDomain:
    grafanaURL:
  clusters:
  - name:
    baseDomain:
    kubecontext:
EOF

}