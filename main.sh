#!/usr/bin/env bash

# Source the environment variable
source ./env_vars

# Source the utils which required in this main func
source utils/helper.sh
source utils/run_test.sh
source utils/setup_tools.sh
source utils/gen_context.sh
source utils/spoke.sh

OLD_IFS="$IFS"
IFS=","
_test_case=$(phase_type $ACM_TEST_GROUP)
typecase_array=($_test_case)
IFS="$OLD_IFS"

function init() {
    # This function was used to install the required tools, generate the context, and so on
    init_tools
}

init

if [[ $USER_ENV == "true" ]]; then

    if [[ ! -z $OCP_TOKEN ]]; then
        generate_context_withtoken $OCP_TOKEN $OCP_URL "customer"
    else
        generate_context $HUB_USERNAME $HUB_PASSWORD $OCP_URL "customer"
    fi

    generate_spoke_context "customer"

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

    # Get hub cluster related info
    _acm_version=$(get_acm_version "customer")
    _acm_console=$(get_acm_console "customer")

    # Get spoke cluster related info
    _spoke_cluster_name=$(get_spoke_cluster_name "customer")
    _spoke_cluster_platform=$(get_spoke_cluster_platform "customer")
    _spoke_cluster_console=$(get_spoke_cluster_console "customer")
    _spoke_cluster_version=$(get_spoke_cluster_version "customer")

    source utils/gen_report.sh
    generate_md results/${TIME_STAMP}/customer/tmp results/${TIME_STAMP}/customer/report.md $TEST_SNAPSHOT "Regression" "user" $_acm_version $_acm_console $_spoke_cluster_version $_spoke_cluster_console
    push_report results/${TIME_STAMP}
else
    get_supported_type_from_file $ACM_VERSION
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
        generate_spoke_context ${type} ${ACM_VERSION}

        mkdir -p "results/${TIME_STAMP}/${type}-${ACM_VERSION}/results/"
        _base_domain=$(get_basedomain $type $ACM_VERSION)
        _id_provider=$(get_idprovider $type $ACM_VERSION)
        _config_path=$(get_config_path $type $ACM_VERSION)

        for tc in ${typecase_array[@]}
        do
            generate_options $_config_path $_base_domain $tc $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") $_id_provider
            run_test $tc $TIME_STAMP $type $ACM_VERSION
        done

        # Get hub cluster related info
        _acm_version=$(get_acm_version ${type} ${ACM_VERSION})
        _acm_console=$(get_acm_console ${type} ${ACM_VERSION})

        # Get spoke cluster related info
        _spoke_cluster_name=$(get_spoke_cluster_name ${type} ${ACM_VERSION})
        _spoke_cluster_platform=$(get_spoke_cluster_platform ${type} ${ACM_VERSION})
        _spoke_cluster_console=$(get_spoke_cluster_console ${type} ${ACM_VERSION})
        _spoke_cluster_version=$(get_spoke_cluster_version ${type} ${ACM_VERSION})

        source utils/gen_report.sh
        generate_md results/${TIME_STAMP}/${type}-${ACM_VERSION}/tmp results/${TIME_STAMP}/${type}-${ACM_VERSION}/report.md $TEST_SNAPSHOT "Regression" $type $_acm_version $_acm_console $_spoke_cluster_version $_spoke_cluster_console
        push_report results/${TIME_STAMP}
    done
fi
