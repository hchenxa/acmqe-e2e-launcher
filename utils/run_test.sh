#!/usr/bin/env bash

source utils/observability-utils.sh

function run_test() {

    _test_case=$1
    _timestamp=$2
    _env_type=$3
    if [[ $_env_type == "customer" ]]; then
        result_path="$(pwd)/results/${_timestamp}/${_env_type}"
        config_path="$(pwd)/env-context/${_env_type}"
    else
        _cluster_version=$4
        result_path="$(pwd)/results/${_timestamp}/${_env_type}-${_cluster_version}"
        config_path="$(pwd)/env-context/${_env_type}-${_cluster_version}"
    fi
    echo "Start the running $_test_case cases..."

    mkdir -p $result_path/tmp/
    mkdir -p $result_path/cypress-results
    mkdir -p $result_path/results

    case $_test_case in
        "SEARCH")
            sudo $DOCKER run \
            --network host \
            --dns 8.8.8.8 \
            --dns 8.8.4.4 \
            -e BROWSER="chrome" \
            --volume ${config_path}/kubeconfig:/opt/.kube/config \
            --volume ${config_path}/imported-kubeconfig:/opt/.kube/import-kubeconfig \
            --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
            --volume $result_path/results:/results \
            --name search-e2e-${TIME_STAMP} \
            quay.io/open-cluster-management/search-e2e:$TEST_SNAPSHOT

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/search-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "KUI")
            sudo $DOCKER run \
            --network host \
            --env BROWSER="firefox" \
            --volume ${config_path}/kubeconfig:/opt/.kube/config \
            --volume ${result_path}/results:/results \
            --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
            --name kui-web-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/kui-web-terminal-tests:$TEST_SNAPSHOT

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/kui-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "GRC_UI")
            sudo $DOCKER run \
            --volume $result_path/results:/opt/app-root/src/grc-ui/test-output/e2e \
            --volume $result_path/cypress-results:/opt/app-root/src/grc-ui/test-output/cypress \
            --env OC_CLUSTER_URL="${OCP_URL}" \
            --env OC_CLUSTER_PASS="${HUB_PASSWORD}" \
            --env OC_CLUSTER_USER="${HUB_USERNAME}" \
            --env RBAC_PASS="${RBAC_PASS}" \
            --env CYPRESS_STANDALONE_TESTSUITE_EXECUTION=FALSE \
            --name grc-ui-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/grc-ui-tests:${TEST_SNAPSHOT}

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/grc-ui-${TIME_STAMP}-$(basename $f)"
            done

            for f in $result_path/cypress-results/*; do
                mv "$f" "$result_path/tmp/grc-ui-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "GRC_FRAMEWORK")
            _managed_cluster_name=$(cat ${config_path}/managed_cluster_name)
            sudo $DOCKER run \
            --network host \
            --volume $result_path/results:/go/src/github.com/open-cluster-management/governance-policy-framework/test-output \
            --volume $config_path/kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_hub \
            --volume $config_path/imported-kubeconfig:/go/src/github.com/open-cluster-management/governance-policy-framework/kubeconfig_managed \
            --env MANAGED_CLUSTER_NAME="$_managed_cluster_name" \
            --name grc-policy-framework-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/grc-policy-framework-tests:$TEST_SNAPSHOT

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/grc-framework-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "CONSOLE_UI")
           ## The console-ui-tests can be run 2.0.x and 2.1.x
            if [[ $ACM_VERSION =~ 2.0 || $ACM_VERSION =~ 2.1 ]]; then
                sudo $DOCKER run \
                --volume $result_path/results:/results \
                --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
                --volume ${config_path}/imported-kubeconfig:/opt/.kube/import-kubeconfig \
                --env TEST_GROUP=e2e \
                --env BROWSER='chrome' \
                --name console-ui-tests-${TIME_STAMP} \
                quay.io/open-cluster-management/console-ui-tests:$TEST_SNAPSHOT
            else
                echo "The console ui tests only can be run 2.0 and 2.1"
            fi

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/console-ui-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "CLUSTER_LIFECYCLE")
            ;;
        "APP_UI")
            sudo $DOCKER run \
            --volume ${result_path}/results:/results \
            --volume ${config_path}/imported-kubeconfig:/usr/src/app/tests/cypress/config/import-kubeconfig \
            --volume ${config_path}/${_test_case}/options.yaml:/resources/options.yaml \
            --env CYPRESS_TEST_MODE="functional" \
            --env CYPRESS_OC_IDP="$(get_idprovider $_env_type $ACM_VERSION)" \
            --env CYPRESS_OC_CLUSTER_USER="${HUB_USERNAME}" \
            --env CYPRESS_OC_CLUSTER_PASS="${HUB_PASSWORD}" \
            --env CYPRESS_OC_CLUSTER_URL="${OCP_URL}" \
            --env CYPRESS_BASE_URL=https://$(get_acm_console $_env_type) \
            --env GITHUB_USER="${GITHUB_USER}" \
            --env GITHUB_TOKEN="${GITHUB_TOKEN}" \
            --env GITHUB_PRIVATE_URL=https://github.com/open-cluster-management/app-ui-e2e-private-git \
            --env OBJECTSTORE_PRIVATE_URL="${OBJECTSTORE_PRIVATE_URL}" \
            --env OBJECTSTORE_ACCESS_KEY="${OBJECTSTORE_ACCESS_KEY}" \
            --env OBJECTSTORE_SECRET_KEY="${OBJECTSTORE_SECRET_KEY}" \
            --env HELM_PRIVATE_URL=https://raw.githubusercontent.com/open-cluster-management/app-ui-e2e-private-helm/master \
            --env HELM_USERNAME="${GITHUB_USER}" \
            --env HELM_PASSWORD="${GITHUB_TOKEN}" \
            --env HELM_CHART_NAME=mychart \
            --env BROWSER="chrome" \
            --name application-ui-tests-${TIME_STAMP} \
            quay.io/open-cluster-management/application-ui-tests:${TEST_SNAPSHOT}

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/app-ui-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "APP_BACKEND")
            sudo $DOCKER run \
            --volume ${config_path}/kubeconfig:/opt/e2e/default-kubeconfigs/hub \
            --volume ${config_path}/imported-kubeconfig:/opt/e2e/default-kubeconfigs/import-kubeconfig \
            --volume ${result_path}/results:/opt/e2e/client/canary/results \
            --env KUBE_DIR=/opt/e2e/default-kubeconfigs \
            --name applifecycle-backend-e2e-${TIME_STAMP} \
            quay.io/open-cluster-management/applifecycle-backend-e2e:$TEST_SNAPSHOT

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/app-backend-${TIME_STAMP}-$(basename $f)"
            done

            ;;
        "OBSERVABILITY")
            if [[ $_env_type == "customer" ]]; then
                _mco_enabled=$(get_mco_cr $_env_type $_cluster_version)
            else
                _mco_enabled=$(get_mco_cr $_env_type $_cluster_version)
            fi

            if [[ $_mco_enabled == "true" ]]; then
                sudo $DOCKER run \
                --net host \
                --volume ${result_path}/results:/results \
                --volume ${config_path}/kubeconfig:/opt/.kube/config \
                --volume ${config_path}/${_test_case}/resources:/resources \
                --name observability-e2e-test-${TIME_STAMP} \
                --env SKIP_INSTALL_STEP=true \
                --env SKIP_UNINSTALL_STEP=true \
                quay.io/open-cluster-management/observability-e2e-test:${TEST_SNAPSHOT}
            else
                sudo $DOCKER run \
                --net host \
                --volume ${result_path}/results:/results \
                --volume ${config_path}/kubeconfig:/opt/.kube/config \
                --volume ${config_path}/${_test_case}/resources:/resources \
                --name observability-e2e-test-${TIME_STAMP} \
                --env SKIP_INSTALL_STEP=false \
                --env SKIP_UNINSTALL_STEP=false \
                quay.io/open-cluster-management/observability-e2e-test:${TEST_SNAPSHOT}
            fi

            for f in $result_path/results/*; do
                mv "$f" "$result_path/tmp/observability-${TIME_STAMP}-$(basename $f)"
            done

            ;;
    esac

}
