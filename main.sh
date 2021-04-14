#!/usr/bin/env bash

source utils/helper.sh
source utils/run_test.sh

export TEST_SNAPSHOT=${TEST_SNAPSHOT:-latest}
export ACM_VERSION=${ACM_VERSION:-2.3}

# This variable will be ready from jenkins configuration, and the value will be like "aws,azure,gcp,roks", so need to split the ',' here as well
export ACM_HUB_TYPE=${ACM_HUB_TYPE:-AWS}

# This variable will be ready from jenkins configuration, and the value will be like "kui,search,observability", so need to split the ',' here as well
export ACM_TEST_GROUP=${ACM_TEST_GROUP:-}

# This variable will be ready from jenkins configuration, and the value will be like "docker" or "podman"
export DOCKER=${DOCKER:-docker}

# This variable will be ready from jenkins configuration which used to pull docker images from quay.io
export QUAY_USERNAME=${QUAY_USERNAME:-}
export QUAY_PASSWORD=${QUAY_PASSWORD:-}

if [[ -z $ACM_VERSION ]]; then
    echo "Please set ACM_VERSION environment variable before running the scripts"
    exit 1
fi

if [[ $(jq -r ".acm_versions[].version == $ACM_VERSION" config/environment.json | grep true | wc -l | sed 's/^ *//') == 0 ]]; then
    echo "can not find the supported ACM_VERSION:$ACM_VERSION, please try to correct the version that the automation supported"
    exit 1
fi

if [[ -z $ACM_TEST_GROUP ]]; then
    echo "Please set ACM_TEST_GROUP environment variable before running the scripts"
    exit 1
fi

if [[ -z $QUAY_USERNAME || -z $QUAY_PASSWORD ]]; then
    echo "Please set QUAY_USERNAME and QUAY_PASSWORD environment variable before running the scripts"
    exit 1
fi

supported_hub_type=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION)|.envs[].type" config/environment.json | xargs | sed 's/\ /,/g')
echo "The supported hub type is $supported_hub_type"
OLD_IFS="$IFS"
IFS=","
_type=$(phase_type $ACM_HUB_TYPE)
_test_case=$(phase_type $ACM_TEST_GROUP)
type_array=($_type)
typecase_array=($_test_case)
IFS="$OLD_IFS"

_version=$(phase_version $ACM_VERSION)

source utils/gen_context.sh
for type in ${type_array[@]}
do
    # Get the username and password from the environment variable here, and the supported format should like AWS_23_USERNAME and AWS_23_PASSWORD
    _username=${type}_${_version}_USERNAME
    _passwd=${type}_${_version}_PASSWORD
    url=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION) | .envs[] | select(.type == \"$type\") | .ocp_route" config/environment.json)
    generate_context $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") --server=$url $type $ACM_VERSION

    # Generate the imported cluster context
    # First need to check to see if the cluster have imported cluster or not
    _managed_cluster=$(KUBECONFIG=env_context/${type}_${ACM_VERSION}/kubeconfig oc get managedcluster --no-headers --ignore-not-found | awk '{print $1}')
    if [[ $(echo $_managed_cluster | wc -l | sed 's/\ /,/g' ) == 0 ]]; then
        echo "No imported cluster found, please try to import a managed cluster first and rerun the test"
        exit 1
    elif [[ $(echo $_managed_cluster | wc -l | sed 's/\ /,/g' ) == 1 ]]; then
        generate_importcluster_context ${_managed_cluster} ${type} ${ACM_VERSION}
    else
        for mc in $_managed_cluster
        do
            if [[ $mc == "local-cluster" ]]; then
                continue
            else
                # (TODO) Will filter out the unavailable cluster later
                generate_importcluster_context $mc ${type} ${ACM_VERSION}
                break
            fi
        done
    fi
    _base_domain=$(get_basedomain ${type} ${ACM_VERSION})
    _id_provider=$(get_idprovider ${type} ${ACM_VERSION})
    for tc in ${typecase_array[@]}
    do
        generate_options ${type} ${ACM_VERSION} ${_base_domain} $tc $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") $_id_provider
        run_test ${type} ${ACM_VERSION} $tc
    done
done

# # The function will generate the report
# generate_report