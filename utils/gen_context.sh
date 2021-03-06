#!/usr/bin/env bash

function generate_context() {
    # generate the kubeconfig which used to connect to the cluster
    username=$1
    password=$2
    url=$3
    env_type=$4
    if [[ $env_type == "customer" ]]; then
        _hub_conf_path="env-context/${env_type}"
    else
        cluster_version=$5
        _hub_conf_path="env-context/${env_type}-${cluster_version}"
    fi
    mkdir -p ${_hub_conf_path}
    touch ${_hub_conf_path}/kubeconfig
    KUBECONFIG=${_hub_conf_path}/kubeconfig oc login --insecure-skip-tls-verify=true -u $username -p $password $url
    if [[ $? != 0 ]]; then
        exit 1
    else
        echo "${_hub_conf_path}/kubeconfig"
    fi
}

function generate_context_withtoken() {
    ocp_token=$1
    url=$2
    env_type=$3
    if [[ $env_type == "customer" ]]; then
        _hub_conf_path="env-context/${env_type}"
    else
        cluster_version=$4
        _hub_conf_path="env-context/${env_type}-${cluster_version}"
    fi
    mkdir -p ${_hub_conf_path}
    touch ${_hub_conf_path}/kubeconfig
    KUBECONFIG=${_hub_conf_path}/kubeconfig oc login --insecure-skip-tls-verify=true --token=$ocp_token $url
    if [[ $? != 0 ]]; then
        exit 1
    else
        echo "${_hub_conf_path}/kubeconfig"
    fi
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
            # Hack to make sure the search can run in non kube:admin environment
            cat << EOF > ${config_path}/${test_type}/search-cypress.json
{
  "testFiles": "**/*.spec.js",
  "chromeWebSecurity": false,
  "defaultCommandTimeout": 10000,
  "integrationFolder": "tests/cypress/tests",
  "ignoreTestFiles": ["welcomePage.spec.js"],
  "fixturesFolder": "tests/cypress/fixtures",
  "pluginsFile": "tests/cypress/plugins/index.js",
  "pageLoadTimeout": 90000,
  "numTestsKeptInMemory": 10,
  "screenshotsFolder" : "results/screenshots",
  "supportFile": "tests/cypress/support/index.js",
  "videosFolder": "results/videos",
  "videoUploadOnPasses": false,
  "watchForFileChanges": true,
  "nodeVersion": "system",
  "env": {
    "OC_IDP": "$id_provider"
  },
  "reporter": "cypress-multi-reporters",
  "reporterOptions": {
    "reporterEnabled": "mochawesome, mocha-junit-reporter",
    "mochawesomeReporterOptions": {
      "reportDir": "results/json",
      "reportFilename": "mochawesome-report.json",
      "overwrite": false,
      "html": false,
      "json": true
    },
    "mochaJunitReporterReporterOptions": {
      "mochaFile": "results/cypress-[hash].xml"
    }
  },
  "retries": 2,
  "viewportHeight": 1050,
  "viewportWidth": 1680
}
EOF
            ;;
        "KUI")
            cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  identityProvider: $id_provider
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
        "APP_UI")
          cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  hub:
    baseDomain: $baseDomain
    hubClusterURL: https://api.${baseDomain}:6443
    user: $username
    password: $password
    baseURL: https://multicloud-console.apps.${baseDomain}
    idp: $id_provider
EOF
            ;;
        "CONSOLE_UI")
          cat << EOF > ${config_path}/${test_type}/options.yaml
options:
  hub:
    baseDomain: $baseDomain
    hubClusterURL: https://api.${baseDomain}:6443
    user: $username
    password: $password
    baseURL: https://multicloud-console.apps.${baseDomain}
  identityProvider: $id_provider
EOF
       ;;
    esac
}
