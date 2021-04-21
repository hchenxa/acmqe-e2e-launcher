#!/usr/bin/env bash

function run_test() {

    _test_case=$1
    _timestamp=$2
    _env_type=$3
    if [[ $_env_type == "customer" ]]; then
        result_path="$(pwd)/results/${_timestamp}/${_env_type}/results"
        config_path="$(pwd)/env_context/${_env_type}"
    else
        _cluster_version=$4
        result_path="$(pwd)/results/${_timestamp}/${_env_type}_${_cluster_version}/results"
        config_path="$(pwd)/env_context/${_env_type}_${_cluster_version}"
    fi
    echo "Start the running $_test_case cases..."

    case $_test_case in
        "SEARCH")
            sudo $DOCKER run \
            --network host \
            --dns 8.8.8.8 \
            --dns 8.8.4.4 \
            -e BROWSER="chrome" \
            --volume ${config_path}/kubeconfig:/opt/.kube/config \
            --volume ${config_path}/imported_kubeconfig:/opt/.kube/import-kubeconfig \
            --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
            --volume $result_path:/results \
            --name search-e2e-${TIME_STAMP} \
            quay.io/open-cluster-management/search-e2e:$TEST_SNAPSHOT
            ;;
        "KUI")
            sudo $DOCKER run \
            --network host \
            --env BROWSER="firefox" \
            --volume ${config_path}/kubeconfig:/opt/.kube/config \
            --volume ${result_path}:/results \
            --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
            --name kui-web-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/kui-web-terminal-tests:$TEST_SNAPSHOT
            ;;
        "GRC_UI")
            sudo $DOCKER run \
            --volume $result_path:/opt/app-root/src/grc-ui/test-output/e2e \
            --volume $result_path:/opt/app-root/src/grc-ui/test-output/cypress \
            --env OC_CLUSTER_URL="${OCP_URL}" \
            --env OC_CLUSTER_PASS="${HUB_PASSWORD}" \
            --env OC_CLUSTER_USER="${HUB_USERNAME}" \
            --env RBAC_PASS="${RBAC_PASS}" \
            --env CYPRESS_STANDALONE_TESTSUITE_EXECUTION=FALSE \
            --name grc-ui-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/grc-ui-tests:${TEST_SNAPSHOT}
            ;;
        "GRC_FRAMEWORK")
            _managed_cluster_name=$(cat ${config_path}/managed_cluster_name)
            sudo $DOCKER run \
            --network host \
            --volume $result_path:/go/src/github.com/open-cluster-management/governance-policy-framework/test-output \
            --volume $config_path/kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_hub \
            --volume $config_path/imported_kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_managed \
            --env MANAGED_CLUSTER_NAME="$_managed_cluster_name" \
            --name grc-policy-framework-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/grc-policy-framework-tests:$TEST_SNAPSHOT
            ;;
        "CONSOLE_UI")
            #(TODO)
            ;;
        "CLUSTER_LIFECYCLE")
            ;;
        "APP_UI")
            ;;
        "APP_BACKEND")
            sudo $DOCKER run \
            --volume ${config_path}/kubeconfig:/opt/e2e/default-kubeconfigs/hub \
            --volume ${config_path}/imported_kubeconfig:/opt/.kube/import-kubeconfig \
            --volume ${result_path}:/opt/e2e/client/canary/results \
            --env KUBE_DIR=/opt/e2e/default-kubeconfigs \
            --name applifecycle-backend-e2e-${TIME_STAMP} \
            quay.io/open-cluster-management/applifecycle-backend-e2e:$TEST_SNAPSHOT
            ;;
        "OBSERVABILITY")
            sudo $DOCKER run \
            --net host \
            --volume ${result_path}:/results \
            --volume ${config_path}/kubeconfig:/opt/.kube/config \
            --volume ${config_path}/${_test_case}/resources:/resources \
            --name observability-e2e-test-${TIME_STAMP} \
            --env SKIP_INSTALL_STEP=true \
            --env SKIP_UNINSTALL_STEP=true \
            quay.io/open-cluster-management/observability-e2e-test:${TEST_SNAPSHOT}
            ;;
    esac

}
