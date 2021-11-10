#!/usr/bin/bash

# install.sh - prepare the dependencies for the run.sh
# 
# It only handles installing from scratch and will probably fail on a subsequent run.
# It overuses the &&, &, and backslash line continuation so it could be easily converted
# into a Dockerfile, just by adding `RUN` directives (and `COPY requirements.txt .`).

set -euo pipefail

cd "$(dirname $0)"

curl -sL https://github.com/terraform-docs/terraform-docs/releases/download/v0.12.1/terraform-docs-v0.12.1-linux-amd64 > terraform-docs    & \
curl -sL https://github.com/tfsec/tfsec/releases/download/v0.34.0/tfsec-linux-amd64 > tfsec    & \
curl -sL https://github.com/terraform-linters/tflint/releases/download/v0.20.3/tflint_linux_amd64.zip > tflint.zip    & \
wait
echo Finished successfully all parallel downloads ------------------------------------------------------------------

chmod +x terraform-docs
mv terraform-docs /usr/local/bin/
chmod +x tfsec
mv tfsec /usr/local/bin/

unzip tflint.zip
rm tflint.zip
mv tflint /usr/local/bin/

git --version
terraform-docs --version
tfsec --version
tflint --version
terraform version

echo "Also, the newest release: $(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E "https://.+?-linux-amd64")"
echo "Also, the newest release: $(curl -s https://api.github.com/repos/tfsec/tfsec/releases/latest | grep -o -E "https://.+?tfsec-linux-amd64")"
echo "Also, the newest release: $(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")"

python3 -m pip install -r requirements.txt
