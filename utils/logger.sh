#!/usr/bin/env bash

# The logging function used to output the message in the scripts.
function msg() {
  printf '%b\n' "$1"
}

function success() {
  msg "\33[32m[✔] ${1}\33[0m"
}

function warning() {
  msg "\33[33m[Warning] ${1}\33[0m"
}

function error() {
  msg "\33[31m[✘] ${1}\33[0m"
}

function debug() {
  if [[ ! -z $DEBUG && $DEBUG == true ]]; then
    msg "\33[34m[Debug] ${1}\33[0m"
  fi
}

function info(){
  msg "[INFO] ${1}"
}

function logger(){
  content=$1
  echo "******************************************"
  echo "$content"
  echo "******************************************"
}