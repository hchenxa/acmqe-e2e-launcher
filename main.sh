#!/usr/bin/env bash

export TEST_SNAPSHOT=${TEST_SNAPSHOT:-latest}
export ACM_VERSION=${ACM_VERSION:-2.3}

# This variable will be ready from jenkins configuration, and the value will be like "aws,azure,gcp,roks", so need to split the ',' here as well
export ACM_HUB_TYPE=${ACM_HUB_TYPE:-aws}

if [[ -z $ACM_VERSION ]]; then
    echo "Please set ACM_VERSION environment variable before running the scripts"
    exit 1
fi

if [[ $(jq -r ".acm_versions[].version == $ACM_VERSION" config/environment.json | grep true | wc -l | sed 's/^ *//') == 0 ]]; then
    echo "can not find the supported ACM_VERSION:$ACM_VERSION, please try to correct the version that the automation supported"
    exit 1
fi

supported_hub_type=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION)|.envs[].type" config/environment.json | xargs | sed 's/\ /,/g')
echo "The supported hub type is $supported_hub_type"
OLD_IFS="$IFS"
IFS=","
array=($supported_hub_type)
IFS="$OLD_IFS"

source utils/gen_context.sh
for type in ${array[@]}
do
    # Get the username and password from the environment variable here, and the supported format should like AWS_23_USERNAME and AWS_23_PASSWORD

    url=$(jq -r ".acm_versions[]|select(.version == $ACM_VERSION) | .envs[] | select(.type == \"$type\") | .ocp_route" config/environment.json)
    generate_context $username $passwd --server=$url $type $ACM_VERSION
done


# (TODO) Can have a for loop here to run the generate_context, run_test, generate_report

# The function will generate the cluster context
# source utils/gen_context.sh
# generate_context

# # The function will run test on each of clusters
# run_test

# # The function will generate the report
# generate_report