#!/usr/bin/env bash

source utils/helper.sh
source utils/run_test.sh
source utils/setup_tools.sh
setup_oc
setup_jq
setup_container_client
setup_python_dep

source ./env_vars
source utils/gen_context.sh

OLD_IFS="$IFS"
IFS=","
_test_case=$(phase_type $ACM_TEST_GROUP)
typecase_array=($_test_case)
IFS="$OLD_IFS"

if [[ $USER_ENV == "true" ]]; then
    if [[ ! -z $OCP_TOKEN ]]; then
        generate_context_withtoken $OCP_TOKEN $OCP_URL "customer"
    else
        generate_context $HUB_USERNAME $HUB_PASSWORD $OCP_URL "customer"
    fi
    # (TODO)Some cases required the managed cluster context, will handle this part later
    _managed_cluster=$(get_imported_cluster "env_context/customer/kubeconfig")
    if [[ $_managed_cluster == "" ]]; then
        echo "no managed cluster in the cluster"
    else
        generate_importcluster_context ${_managed_cluster} "customer"
    fi
    _config_path=$(get_config_path customer)

    mkdir -p "results/${TIME_STAMP}/customer/results"
    _base_domain=$(get_basedomain "customer")
    _id_provider=$(get_idprovider "customer")

    for tc in ${typecase_array[@]}
    do
        # (TODO), need to handle when using token to do the authentication here
        generate_options $_config_path $_base_domain $tc $HUB_USERNAME $HUB_PASSWORD $_id_provider
        run_test $tc $TIME_STAMP "customer"
    done
    _acm_version=$(get_acm_version "customer")
    _acm_console=$(get_acm_console "customer")
    source utils/gen_report.sh
    generate_md results/${TIME_STAMP}/customer/results results/${TIME_STAMP}/customer/report.md $TEST_SNAPSHOT "Regression" "user" $_acm_version ${_acm_console} "ImportClusterClaim" $_managed_cluster
    push_report results/${TIME_STAMP}
else
    supported_hub_type=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION)|.envs[].type" config/environment.json | xargs | sed 's/\ /,/g')
    echo "The supported hub type is $supported_hub_type in acm version $ACM_VERSION"
    OLD_IFS="$IFS"
    IFS=","
    _type=$(phase_type $ACM_HUB_TYPE)
    type_array=($_type)
    IFS="$OLD_IFS"
    _version=$(phase_version $ACM_VERSION)

    # Filter the ACM type to run the cases on each of clusters.
    for type in ${type_array[@]}
    do
        # (TODO) The url here may have multi value, need to handle this case later
        url=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION) | .envs[] | select(.type == \"$type\") | .ocp_route" config/environment.json)

        if [[ ! -z $OCP_TOKEN ]]; then
            generate_context_withtoken $OCP_TOKEN $url $type $ACM_VERSION
        else
            # Get the username and password from the environment variable here, and the supported format should like AWS_23_USERNAME and AWS_23_PASSWORD
            # (TODO) Will replace this part by using the 'gspreadsheets' API to get the username and password dynamicly
            _username=${type}_${_version}_USERNAME
            _passwd=${type}_${_version}_PASSWORD

            # (TODO) The url here may have multi value, need to handle this case later
            generate_context $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") $url $type $ACM_VERSION
        fi

        # Generate the imported cluster context
        # First need to check to see if the cluster have imported cluster or not
        # (TODO)Some cases required the managed cluster context, will handle this part later
        _managed_cluster=$(get_imported_cluster "env_context/${type}_${ACM_VERSION}/kubeconfig")
        if [[ $_managed_cluster == "" ]]; then
            echo "no managed cluster in the cluster"
        else
            generate_importcluster_context $_managed_cluster $type $ACM_VERSION
        fi
        mkdir -p "results/${TIME_STAMP}/${type}_${ACM_VERSION}/results/"
        _base_domain=$(get_basedomain $type $ACM_VERSION)
        _id_provider=$(get_idprovider $type $ACM_VERSION)
        _config_path=$(get_config_path $type $ACM_VERSION)

        for tc in ${typecase_array[@]}
        do
            generate_options $_config_path $_base_domain $tc $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") $_id_provider
            run_test $tc $TIME_STAMP $type $ACM_VERSION
        done

        _acm_version=$(get_acm_version ${type} ${ACM_VERSION})
        _acm_console=$(get_acm_console ${type} ${ACM_VERSION})
        source utils/gen_report.sh
        generate_md results/${TIME_STAMP}/${type}_${ACM_VERSION}/results results/${TIME_STAMP}/${type}_${ACM_VERSION}/report.md $TEST_SNAPSHOT "Regression" $type $_acm_version ${_acm_console} "ImportClusterClaim" $_managed_cluster
        push_report results/${TIME_STAMP}
    done
fi
