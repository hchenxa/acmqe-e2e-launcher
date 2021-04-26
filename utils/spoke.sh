#!/usr/bin/env bash


function generate_spoke_context() {

    # Init the spoke cluster context path
    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _spoke_context_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _spoke_context_path="env-context/${_cluster_type}-${_cluster_version}"
    fi

    mkdir -p ${_spoke_context_path}
    touch ${_spoke_context_path}/imported-kubeconfig

    # Generate the spoke cluster context
    if [[ ! -z $SPOKE_API_URL && ! -z $SPOKE_TOKEN ]]; then
        KUBECONFIG="${_spoke_context_path}/imported-kubeconfig" oc login --insecure-skip-tls-verify=true --token=$SPOKE_TOKEN $SPOKE_API_URL
    elif [[ ! -z $SPOKE_API_URL && ! -z $SPOKE_USERNAME && ! -z $SPOKE_PASSWORD ]]; then
        KUBECONFIG="${_spoke_context_path}/imported-kubeconfig" oc login --insecure-skip-tls-verify=true -u $SPOKE_USERNAME -p $SPOKE_PASSWORD $SPOKE_API_URL
    else
        echo "No Spoke info provided by users, will try to select the spoke from the hub cluster"
        _spoke_cluster=$(get_spoke_cluster_from_hub "${_spoke_context_path}/kubeconfig")
        if [[ $_spoke_cluster == "" ]]; then
            echo "no spoke cluster in the cluster"
        elif [[ $_spoke_cluster == "local-cluster" ]]; then
            # If the cluster only have local-cluster, copy the hub cluster context as the imported cluster context.
            cp ${_spoke_context_path}/kubeconfig ${_spoke_context_path}/imported-kubeconfig
        else
            _secret_name=$(KUBECONFIG=${_spoke_context_path}/kubeconfig oc get secret -n $_spoke_cluster | awk '{print $1}' | grep "^$_spoke_cluster.*admin-kubeconfig$")
            if [[ $(uname -s) == "Darwin" ]]; then
                KUBECONFIG=${_spoke_context_path}/kubeconfig oc get secret -n $_spoke_cluster $_secret_name --template={{.data.kubeconfig}} | base64 -D > ${_spoke_context_path}/imported-kubeconfig
            else
                KUBECONFIG=${_spoke_context_path}/kubeconfig oc get secret -n $_spoke_cluster $_secret_name --template={{.data.kubeconfig}} | base64 -d > ${_spoke_context_path}/imported-kubeconfig
            fi
            echo "apiVersion: v1" >> ${_spoke_context_path}/imported-kubeconfig            
        fi
    fi
}

function get_spoke_cluster_from_hub() {
    _kubeconfig_path=$1
    _spoke_cluster=$(KUBECONFIG=$_kubeconfig_path oc get managedcluster --no-headers --ignore-not-found | awk '{print $1}')
    if [[ $(echo "$_spoke_cluster" | wc -l | sed 's/\ //g' ) == 0 ]]; then
        echo ""
    elif [[ $(echo "$_spoke_cluster" | wc -l | sed 's/\ //g' ) == 1 ]]; then
        if [[ $_spoke_cluster == "local-cluster" ]]; then
            echo "local-cluster"
        else
            _imported_by_hive=$(check_imported_cluster ${_kubeconfig_path} ${_spoke_cluster})
            if [[ $_imported_by_hive == 'true' ]]; then
                echo ${_spoke_cluster}
            else
                echo ""
            fi
        fi
    else
        _flag=0
        for mc in $_spoke_cluster
        do
            # Will first use the local-cluster as the spoke cluster
            if [[ $mc == "local-cluster" ]]; then
                echo "local-cluster"
                break
            else
                # (TODO) Will filter out the unavailable cluster later
                _imported_by_hive=$(check_imported_cluster ${_kubeconfig_path} $mc)
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

function check_imported_cluster() {
    _kubeconfig_path=$1
    _cluster_namespace=$2
    if [[ $(KUBECONFIG=$_kubeconfig_path oc get clusterdeployment -n $_cluster_namespace | wc -l | sed 's/^ *//') == 0 ]]; then
        # If no clusterdeployment exists in the namespace, that means the cluster was imported.
        echo "false"
    else
        # If there have clusterdeployment exists in the namespace, that means the cluster was created by hive.
        echo "true"
    fi
}

function get_spoke_cluster_name() {
    # Init the spoke cluster context path
    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _spoke_context_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _spoke_context_path="env-context/${_cluster_type}-${_cluster_version}"
    fi
    # Get the cluster name from clusterclaim, and the clusterclaim was introduced in v2.2.
    KUBECONFIG=${_spoke_context_path}/imported-kubeconfig oc get clusterclaim id.k8s.io -o jsonpath={.spec.value} > ${_spoke_context_path}/managed_cluster_name
}

function get_spoke_cluster_console() {
    # Init the spoke cluster context path
    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _spoke_context_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _spoke_context_path="env-context/${_cluster_type}-${_cluster_version}"
    fi
    echo $(KUBECONFIG=$_spoke_context_path/imported-kubeconfig oc get clusterclaim consoleurl.cluster.open-cluster-management.io -o jsonpath={.spec.value})
}

function get_spoke_cluster_version() {
    # Init the spoke cluster context path
    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _spoke_context_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _spoke_context_path="env-context/${_cluster_type}-${_cluster_version}"
    fi

    _product_type=$(KUBECONFIG=$_spoke_context_path/imported-kubeconfig oc get clusterclaim product.open-cluster-management.io -o jsonpath={.spec.value})
    if [[ $_product_type == "OpenShift" ]]; then
        echo $(KUBECONFIG=$_spoke_context_path/imported-kubeconfig oc get clusterclaim version.openshift.io -o jsonpath={.spec.value})
    else
        echo $(KUBECONFIG=$_spoke_context_path/imported-kubeconfig oc get clusterclaim kubeversion.open-cluster-management.io -o jsonpath={.spec.value})
    fi
}

function get_spoke_cluster_platform() {
    # Init the spoke cluster context path
    _cluster_type=$1
    if [[ $_cluster_type == "customer" ]]; then
        _spoke_context_path="env-context/${_cluster_type}"
    else
        _cluster_version=$2
        _spoke_context_path="env-context/${_cluster_type}-${_cluster_version}"
    fi
    echo $(KUBECONFIG=$_spoke_context_path/imported-kubeconfig oc get clusterclaim platform.open-cluster-management.io -o jsonpath={.spec.value})
}
