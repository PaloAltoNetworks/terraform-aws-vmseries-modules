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

package bootstrap

import (
	"net/http"
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/generictt"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestMain(t *testing.T) {
	destroyFunc, terraformOptions := generictt.GenericTest(t, nil)
	defer destroyFunc()

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
