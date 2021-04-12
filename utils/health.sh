#!/usr/bin/env bash

# function verify_hub_connection() {
#   set -e
#   echo "Connect to hub: $CAUS_HUB_BASEDOMAIN as user: $CAUS_HUB_USERNAME at: https://api.$CAUS_HUB_BASEDOMAIN:6443"
#   HUB_KUBECONFIG=/tmp/hub
#   rm -rf $HUB_KUBECONFIG
#   export KUBECONFIG=$HUB_KUBECONFIG
#   if [[ -n $CAUS_HUB_TOKEN || $CAUS_HUB_TOKEN != "" ]]; then
#     printf "Setting up hub kubeconfig with token ..."
#     oc login -s https://api.$CAUS_HUB_BASEDOMAIN:6443 --token=$CAUS_HUB_TOKEN --insecure-skip-tls-verify
#   else
#     printf "Setting up hub kubeconfig with username/password ..."
#     oc login -s https://api.$CAUS_HUB_BASEDOMAIN:6443 -u $CAUS_HUB_USERNAME -p $CAUS_HUB_PASSWORD --insecure-skip-tls-verify
#   fi
#   oc cluster-info
#   oc get nodes
#   export HUB_OCP_VERSION=$(oc version | grep Server | cut -d':' -f2)
#   unset KUBECONFIG
# }