// Terratest-powered Go code and Terraform code used together to automate tests for `../../modules/bootstrap`.
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
// Cloud resources are destroyed automatically after the test, no cleanup is normally required.
//
// VScode users should keep `Go: Test On Save` at the default false value, and not set to true. This option is spelled
// `go.testOnSave` in settings.json.

package bootstrap

import (
	"net/http"
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/generictt"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestMain tests the main.tf as well as other *.tf files residing in this directory.
func TestMain(t *testing.T) {
	// The minimum is to run the bare terratest like this:
	//   generictt.GenericTest(t, nil, nil)
	//
	// But we want to perform customized function which we call CheckBucketHttpGet, so:
	generictt.GenericTest(t, nil, CheckBucketHttpGet)
}

// CheckBucketHttpGet checks whether the Bucket's HTTP response code is greater than 401.
// It requires Internet connectivity to AWS S3.
// CheckBucketHttpGet is compatible with the specification generictt.CheckFunc.
func CheckBucketHttpGet(t *testing.T, terraformOptions *terraform.Options) {
	resp, err := http.Get("https://" + terraform.Output(t, terraformOptions, "bucket_domain_name"))
	if err != nil {
		t.Errorf("on S3 HTTP GET: %v\n", err)
		return
	}
	if resp.StatusCode <= 401 {
		t.Errorf("Mismatched HTTP status on a GET of the S3 bucket:\ngot:  %v\nwant: above 401\n", resp.StatusCode)
	}
}
