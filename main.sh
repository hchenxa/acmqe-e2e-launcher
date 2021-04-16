#!/usr/bin/env bash

source utils/helper.sh
source utils/run_test.sh
source utils/setup_tools.sh

# This variable was used to check if the job was using user environment, if yes, user need to provide the login creds.
export USER_ENV=${$USER_ENV:-false}

export TEST_SNAPSHOT=${TEST_SNAPSHOT:-latest}
export ACM_VERSION=${ACM_VERSION:-2.3}

# This variable will be ready from jenkins configuration, and the value will be like "aws,azure,gcp,roks", so need to split the ',' here as well
export ACM_HUB_TYPE=${ACM_HUB_TYPE:-AWS}

# This variable will be ready from jenkins configuration, and the value will be like "kui,search,observability", so need to split the ',' here as well
export ACM_TEST_GROUP=${ACM_TEST_GROUP:-}

# This variable will be ready from jenkins configuration, and the value will be like "docker" or "podman"
export DOCKER=${DOCKER:-docker}

# This variable will be ready from jenkins configuration which used to pull docker images from quay.io
export QUAY_USERNAME=${QUAY_USERNAME:-kubeadmin}
export QUAY_PASSWORD=${QUAY_PASSWORD:-}

# This variable was used for current report test, will be removed later.
export GEN_REPORT_ONLY=${GEN_REPORT_ONLY:-false}

setup_oc
setup_jq
setup_container_client

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

sudo $DOCKER login -u $QUAY_USERNAME -p $QUAY_PASSWORD quay.io/open-cluster-management
if [[ $? -ne 0 ]]; then
    echo "can not login quay.io with the username and password you provided"
    exit 1
fi

supported_hub_type=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION)|.envs[].type" config/environment.json | xargs | sed 's/\ /,/g')
echo "The supported hub type is $supported_hub_type in acm version $ACM_VERSION"
OLD_IFS="$IFS"
IFS=","
_type=$(phase_type $ACM_HUB_TYPE)
_test_case=$(phase_type $ACM_TEST_GROUP)
type_array=($_type)
typecase_array=($_test_case)
IFS="$OLD_IFS"

_version=$(phase_version $ACM_VERSION)

# _timestamp=$(date "+%Y%m%d%H%M")
_timestamp="202104151650"

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
    if [[ $(echo "$_managed_cluster" | wc -l | sed 's/\ //g' ) == 0 ]]; then
        echo "No imported cluster found, please try to import a managed cluster first and rerun the test"
        exit 1
    elif [[ $(echo "$_managed_cluster" | wc -l | sed 's/\ //g' ) == 1 ]]; then
        _imported_by_hive=$(check_imported_cluster ${type} ${ACM_VERSION} ${_managed_cluster})
        if [[ $_imported_by_hive == 'true' ]]; then
            generate_importcluster_context ${_managed_cluster} ${type} ${ACM_VERSION}
        else
            echo "No cluster created by Hive"
        fi
    else
        _flag=0
        for mc in $_managed_cluster
        do
            if [[ $mc == "local-cluster" ]]; then
                continue
            else
                # (TODO) Will filter out the unavailable cluster later
                _imported_by_hive=$(check_imported_cluster ${type} ${ACM_VERSION} ${_managed_cluster})
                if [[ $_imported_by_hive == 'true' ]]; then
                    generate_importcluster_context $mc ${type} ${ACM_VERSION}
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
    mkdir -p "results/${_timestamp}/${type}_${ACM_VERSION}"
    _base_domain=$(get_basedomain ${type} ${ACM_VERSION})
    _id_provider=$(get_idprovider ${type} ${ACM_VERSION})
    if [[ $GEN_REPORT_ONLY == false ]]; then
        for tc in ${typecase_array[@]}
        do
            generate_options ${type} ${ACM_VERSION} ${_base_domain} $tc $(eval echo '$'"$_username") $(eval echo '$'"$_passwd") $_id_provider
            run_test ${type} ${ACM_VERSION} $tc $_timestamp
        done
    fi
    source utils/gen_report.sh
    generate_md results/${_timestamp}/${type}_${ACM_VERSION} results/${_timestamp}/${type}_${ACM_VERSION}/result.md $TEST_SNAPSHOT "test" $type $ACM_VERSION "ClusterClaim" "ImportClusterClaim" hchentest
done
