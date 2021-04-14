#!/usr/bin/env bash

function run_test() {
    env_type=$1
    cluster_version=$2
    test_type=$3

    echo "Start the running $test_type cases..."

    case $test_type in
        SEARCH)
            ;;
        KUI)
            $DOCKER run \
            --network host \
            --env BROWSER="firefox" \
            --volume env_context/${env_type}_${cluster_version}/kubeconfig:/opt/.kube/config \
            --volume results:/results \
            --volume env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            quay.io/open-cluster-management/kui-web-terminal-tests:$TEST_SNAPSHOT
            ;;
    esac

}