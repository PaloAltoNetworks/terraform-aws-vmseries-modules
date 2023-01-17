// Terratest-powered Go code and Terraform code used together to automate tests for `../../modules/subnet_set`.
//
// Quick start:
//
// 1. Install Go at the latest 1.* version: https://golang.org/
//
// 2. Install Terraform at the specific version that you'd like to test. Put it in your PATH.
//
// 3. Set AWS_REGION environment variable and also e.g. AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or similar.
//
// 4. Make sure this code is checked out into your GOPATH, see: go env GOPATH
//
// 5. Run: go test -v
//
// Do not however run `go test -v .` or similar. Specifying a package (that extra dot) enables caching, which is
// incompatible with Terraform.
//
// However to run all the tests in parallel:   cd tests ; go test -count 1 ./...
//
// Cloud resources are destroyed automatically after the test, no cleanup is normally required.
//
// VScode users should keep `Go: Test On Save` at the default false value, and not set to true. This option is spelled
// `go.testOnSave` in settings.json.
package subnet_set_mod

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
)

// TestMain tests the main.tf as well as other *.tf files residing in this directory.
func TestSubnetSetModulePlanOnly(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: ".",
	})

	// Schedule `terraform destroy` at the end of the test, to clean up the created resources.
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform plan` and fail the test if there are any errors.
	// This specific test is not intended to execute `terraform apply` at all.
	terraform.InitAndPlan(t, terraformOptions)
}
