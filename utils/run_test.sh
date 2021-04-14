#!/usr/bin/env bash

function run_test() {
    env_type=$1
    cluster_version=$2
    test_type=$3

    echo "Start the running $test_type cases..."

    case $test_type in
        SEARCH)
            $DOCKER run \
            --network host \
            --dns 8.8.8.8 \
            --dns 8.8.4.4 \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/opt/.kube/config \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/imported_kubeconfig:/opt/.kube/import-kubeconfig \
            --volume $(pwd)/results:/results \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            quay.io/open-cluster-management/search-e2e:$TEST_SNAPSHOT
            ;;
        KUI)
            $DOCKER run \
            --network host \
            --env BROWSER="firefox" \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/opt/.kube/config \
            --volume $(pwd)/results:/results \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            quay.io/open-cluster-management/kui-web-terminal-tests:$TEST_SNAPSHOT
            ;;
        GRC_UI)
            ;;
        GRC_FRAMEWORK)
            managed_cluster_name=$(cat env_context/${env_type}_${cluster_version}/managed_cluster_name)
            $DOCKER run \
            --network host \
            --volume $(pwd)/results:/go/src/github.com/open-cluster-management/governance-policy-framework/test-output \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_hub \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/imported_kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_managed \
            --env MANAGED_CLUSTER_NAME="$managed_cluster_name" \
            quay.io/open-cluster-management/grc-policy-framework-tests:$TEST_SNAPSHOT
            ;;
        CONSOLE_UI)
            ;;
        CLUSTER_LIFECYCLE)
            ;;
        APP_UI)
            ;;
        APP_BACKEND)
            ;;
    esac

}