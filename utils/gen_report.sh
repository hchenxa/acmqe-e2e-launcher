#!/usr/bin/env bash

function generate_md() {
    python3 utils/report/generate_md.py $@
}

function generate_slack() {
    # (TODO) generate the slack info
    echo "generate the slack info"
}

function push_report() {
    _timestamp=$1
    echo "Push the report to github"
    
}