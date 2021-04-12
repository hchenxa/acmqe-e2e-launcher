#!/usr/bin/env bash

if [[ -z $ACM_VERSION ]]; then
    echo "Please set ACM_VERSION environment variable before running the scripts"
    exit 1
fi

# (TODO) Compare the ACM version here. will implement here later
# yq e '.acm_versions | select(.version==2.2)' config/environment.yaml

if [[ $(jq -r '.acm_versions[].version == $ACM_VERSION' environment.json | grep true | wc -l) == '0' ]]; then
    echo "can not find the supported $ACM_VERSION, please try to correct the version that the automation supported"
    exit 1
fi

# Can have a for loop here to run the generate_context, run_test, generate_report

# The function will generate the cluster context
generate_context()

# The function will run test on each of clusters
run_test()

# The function will generate the report
generate_report()