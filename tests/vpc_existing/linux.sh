#!/bin/bash

set -Eeuo pipefail

# TODO rewrite all this in Terratest (portable golang instead of nonportable bash).
tf="$1"

# Destroy an empty state could fail - test for this kind of bug.
"$tf" destroy -var 'switch=true'  -compact-warnings -input=false -auto-approve

# Initialize.
"$tf"   apply -var 'switch=true'  -compact-warnings -input=false -auto-approve

# Do not use apply -refresh=false anywhere - catch the known refresh bug.
"$tf"   apply -var 'switch=true'  -compact-warnings -input=false -auto-approve

printf "\n\n  Check if all subnets survived last step without a destroy.\n\n\n"

# Change a dynamic attribute.
"$tf"   apply -var 'switch=false' -compact-warnings -input=false -auto-approve

printf "\n\n  Check if all subnets survived last step without a destroy.\n\n\n"

"$tf" destroy -var 'switch=false' -compact-warnings -input=false -auto-approve

printf "\n\n  Check if all resources are destroyed.\n\n\n"

printf "\n\n  You can run:    rm terraform.tfstate\n\n\n"
# TODO centralize tfstate:
# Even when a CI action results in a leftover tfstate, the dev should be able to inspect the leftover tfstate,
# fix it, and then run a tf destroy manually.
