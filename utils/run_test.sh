#!/usr/bin/env bash

function run_test() {
    env_type=$1
    cluster_version=$2
    test_type=$3
    result_path="$(pwd)/results/$4/${env_type}_${cluster_version}/"

    echo "Start the running $test_type cases..."

    case $test_type in
        "SEARCH")
            sudo $DOCKER run \
            --network host \
            --dns 8.8.8.8 \
            --dns 8.8.4.4 \
            -e BROWSER="chrome" \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/opt/.kube/config \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/imported_kubeconfig:/opt/.kube/import-kubeconfig \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            --volume $result_path/:/results \
            quay.io/open-cluster-management/search-e2e:$TEST_SNAPSHOT
            ;;
        "KUI")
            sudo $DOCKER run \
            --network host \
            --env BROWSER="firefox" \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/opt/.kube/config \
            --volume $result_path/:/results \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            quay.io/open-cluster-management/kui-web-terminal-tests:$TEST_SNAPSHOT
            ;;
        "GRC_UI")
            sudo $DOCKER run \
            --volume $result_path/results:/opt/app-root/src/grc-ui/test-output/e2e \
            --volume $result_path/results-cypress:/opt/app-root/src/grc-ui/test-output/cypress \
            --env OC_CLUSTER_URL="https://api.${HUB_BASEDOMAIN}:6443" \
            --env OC_CLUSTER_PASS="${HUB_PASSWORD}" \
            --env OC_CLUSTER_USER="${HUB_USERNAME}" \
            --env RBAC_PASS="${RBAC_PASS}" \
            --env CYPRESS_STANDALONE_TESTSUITE_EXECUTION=FALSE \
            --env MANAGED_CLUSTER_NAME="import-${TRAVIS_BUILD_ID}" \
            quay.io/open-cluster-management/grc-ui-tests:${TEST_SNAPSHOT}
            ;;
        "GRC_FRAMEWORK")
            managed_cluster_name=$(cat env_context/${env_type}_${cluster_version}/managed_cluster_name)
            sudo $DOCKER run \
            --network host \
            --volume $result_path/:/go/src/github.com/open-cluster-management/governance-policy-framework/test-output \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_hub \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/imported_kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_managed \
            --env MANAGED_CLUSTER_NAME="$managed_cluster_name" \
            quay.io/open-cluster-management/grc-policy-framework-tests:$TEST_SNAPSHOT
            ;;
        "CONSOLE_UI")
            sudo $DOCKER run \
            --volume $result_path:/results \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/${test_type}/options.yaml:/resources/options.yaml \
            --volume $kubeconfig_dir:/usr/src/app/tests/cypress/config/import-kubeconfig \
            --env TEST_GROUP="console-ui" \
            --env BROWSER='chrome' \
            quay.io/open-cluster-management/console-ui-tests:${TEST_SNAPSHOT}
            ;;
        "CLUSTER_LIFECYCLE")
            ;;
        "APP_UI")
            ;;
        "APP_BACKEND")
            sudo $DOCKER run \
            --volume $result_path/:/opt/e2e/client/canary/results \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/kubeconfig:/opt/e2e/default-kubeconfigs/hub \
            --volume $(pwd)/env_context/${env_type}_${cluster_version}/imported_kubeconfig:/opt/e2e/default-kubeconfigs/import-kubeconfig \
            --env KUBE_DIR=/opt/e2e/default-kubeconfigs \
            --name app-backend-e2e \
            quay.io/open-cluster-management/applifecycle-backend-e2e:${TEST_SNAPSHOT}
            ;;
        "OBSERVABILITY")
            ;;
    esac

}
