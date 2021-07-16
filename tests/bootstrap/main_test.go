// Terratest-powered Go code and Terraform code used together to automate tests for `../../modules/bootstrap`.
//
// Quick Start:
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
// The test resources are destroyed automatically after the test, no cleanup is normally required.
//
// Do not specify Go packages, for example do not run `go test -v .` or similar. The dot at the end
// enables caching, which is incompatible with Terraform code.
//
// VScode users should keep `Go: Test On Save` on default false, and not set to true. (The same option
// is spelled `go.testOnSave` in settings.json.)

package t

import (
	"net/http"
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraform(t *testing.T) {
	t.Parallel()

	// Assign standard variables.
	switchme := "true"

	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: ".",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"switchme": switchme,
		},
	})

	// Schedule `terraform destroy` at the end of the test, to clean up the created resources.
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	want := "true"

	reVerifiableBool := regexp.MustCompile("correct$")

	for output := range terraform.OutputAll(t, terraformOptions) {
		if !reVerifiableBool.MatchString(output) {
			continue
		}

		got := terraform.Output(t, terraformOptions, output)

		if got != want {
			t.Errorf("Mismatched result for terraform output %q:\ngot:  %q\nwant: %q\n", output, got, want)
		}
	}

	// Run `terraform init` and `terraform apply` again, with modified input.
	// This tests that previously existing cloud resources can be successfully modified.
	terraformOptions.Vars["switchme"] = "false"
	terraform.InitAndApply(t, terraformOptions)

	// Try to interact with a SUT outside of Terraform. Requires Internet connectivity to AWS S3.
	resp, err := http.Get("https://" + terraform.Output(t, terraformOptions, "bucket_domain_name"))
	if err != nil {
		t.Errorf("on S3 HTTP GET: %v\n", err)
		return
	}
	if resp.StatusCode <= 401 {
		t.Errorf("Mismatched HTTP status on a GET of the S3 bucket:\ngot:  %v\nwant: above 401\n", resp.StatusCode)
	}
}
