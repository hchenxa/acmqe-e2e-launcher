#!/usr/bin/env bash


function checkout_canary() {
    GITHUB_TOKEN=$1
    git clone https://$GITHUB_TOKEN@github.com/open-cluster-management/canary-scripts.git
}   