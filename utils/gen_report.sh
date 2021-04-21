#!/usr/bin/env bash

function generate_md() {
    python3 utils/report/generate_md.py $@
}

function generate_slack() {
    # (TODO) generate the slack info
    echo "generate the slack info"
}

function push_report() {
    if [[ -z $GITHUB_TOKEN ]]; then
        echo "Push report requied the GITHUB_TOKEN"
        exit 1
    fi
    _report_location=$1
    echo "Push the report to github"
    if [[ -d "/tmp/acm_regression/report" ]]; then
        rm -rf /tmp/acm_regression/report
    fi
    git clone --single-branch --branch main https://${GITHUB_TOKEN}@github.com/hchenxa/report.git /tmp/acm_regression/report
    cp -r $_report_location /tmp/acm_regression/report
    pushd /tmp/acm_regression/report
    git add $(basename $_report_location)
    git status
    git config --global user.email "huichen@redhat.com"
    git config --global user.name "hchenxa"
    git diff-index --quiet HEAD || git commit -am "Save Regression Results ${_report_location}"
    git push
    popd
}