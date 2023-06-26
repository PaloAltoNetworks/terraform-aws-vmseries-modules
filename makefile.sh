#!/bin/bash

set -o pipefail
set -e

COMMAND=$1

case $1 in
  init)
    echo "::  INITIALIZING TERRAFORM  ::"
    terraform init
    echo
    ;;

  validate)
    echo "::  INITIALIZING TERRAFORM  ::"
    terraform init -backend=false
    echo
    echo "::  VALIDATING CODE  ::"
    terraform validate
    echo
    ;;

  test)  
    echo "::  DOWNLOADING GO DEPENDENCIES  ::"
    go get -v -t -d && go mod tidy
    echo
    echo "::  EXECUTING TERRATEST  ::"
    go test -v -timeout 120m -count=1
    echo
    ;;

  destroy)
    echo "::  DESTROYING INFRASTRUCTURE  ::"
    for i in {1..3}; do terraform destroy -auto-approve -var-file=example.tfvars && break || sleep 3; done
    ;;

  *)
    echo "ERROR: wrong param passed:: [$1]"
    exit 1

esac
