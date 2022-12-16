#!/bin/bash

# PART 0 - set current Terraform version

current_terraform_version=`tfenv version-name`
echo "Currently used Terraform version: $current_terraform_version"

# PART 1 - install multiple Terraform versions

export TF_VERSION_REGEXP="^\s*1.0.|^\s*1.1.|^\s*1.2.|^\s*1.3."
export TF_VERSION_SKIP="rc|alpha|beta"
instalable=`tfenv list-remote | egrep "$TF_VERSION_REGEXP" | egrep -v "$TF_VERSION_SKIP"`
installed=`tfenv list`
for tfversion in $instalable; do
    echo "Installing Terraform version: $tfversion"
    tfenv install $tfversion
done
echo "Installed Terraform versions: $installed"

### PART 2 - test examples with one of the selected versions

use_terraform_version="1.0.2"
echo "Execute example with Terraform in version: $use_terraform_version"
tfenv use $use_terraform_version
go test -v -timeout 300m -count=1 | tee examples_test.log

### PART 3 - set recently used Terraform version

echo "Restore recently used Terraform version: $current_terraform_version"
tfenv use $current_terraform_version
tfenv version-name
