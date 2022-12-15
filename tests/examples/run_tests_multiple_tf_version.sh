#!/bin/bash

tfenv version-name
tfenv use latest

# export TF_VERSION_REGEXP="^\s*1.0.|^\s*1.1.|^\s*1.2.|^\s*1.3."
export TF_VERSION_REGEXP="^\s*1.0.2"
export TF_VERSION_SKIP="rc|alpha|beta"

instalable=`tfenv list-remote | egrep "$TF_VERSION_REGEXP" | egrep -v "$TF_VERSION_SKIP"`
installed=`tfenv list | egrep "$TF_VERSION_REGEXP" | egrep -v "$TF_VERSION_SKIP"`

for tfversion in $instalable; do
    echo "Terraform version: $tfversion"
    tfenv install $tfversion
done

for tfversion in $installed; do
    echo "Terraform version: $tfversion"
    tfenv use $tfversion
    go test -v -timeout 300m -count=1
done