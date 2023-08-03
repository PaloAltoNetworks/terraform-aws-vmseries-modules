package bootstrap

import (
	"fmt"
	"math/rand"
	"net/http"
	"testing"
	"time"

	"github.com/PaloAltoNetworks/terraform-modules-vmseries-tests-skeleton/pkg/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleBootstrapWhileCreatingIamRoleForBootstrapModule(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:         ".",
		Vars:                 map[string]interface{}{},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check role name
		{
			OutputName: "iam_role_name",
			Operation:  testskeleton.NotEmpty,
		},
		{
			OutputName:    "iam_role_name",
			Operation:     testskeleton.StartsWith,
			ExpectedValue: "a",
			Message:       "Role name should start from a",
		},

		// check role ARN
		{
			OutputName: "iam_role_arn",
			Operation:  testskeleton.NotEmpty,
		},
		{
			OutputName:    "iam_role_arn",
			Operation:     testskeleton.StartsWith,
			ExpectedValue: "arn:aws:iam::",
			Message:       "Role ARN should start from arn:aws:iam::",
		},

		// check access to S3 bucket with bootstrap files
		{
			Operation:  testskeleton.CheckFunctionWithOutput,
			Check:      CheckHttpGetS3BucketBootstrapFile,
			OutputName: "bucket_domain_name",
			Message:    "HTTP response code > 401 expected while accessing S3 bucket with bootstrap files",
		},
	}

	// deploy test infrastructure and verify outputs and verify no changes are required after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}

// CheckBucketHttpGet checks whether the Bucket's HTTP response code is greater than 401 (expected forbidden access)
// It requires Internet connectivity to AWS S3.
// CheckHttpGetS3BucketBootstrapFile is compatible with the specification testskeleton.CheckFunction.
func CheckHttpGetS3BucketBootstrapFile(t *testing.T, outputValue string) bool {
	resp, err := http.Get("https://" + outputValue)
	if err != nil {
		t.Errorf("Error S3 HTTP GET: %v\n", err)
		return false
	}
	t.Logf("S3 HTTP GET status code: %v", resp.StatusCode)
	return resp.StatusCode > 401
}

func TestErrorForModuleBootstrapWhileNotCreatingIamRoleAndNotPassingIamRoleNameForBootstrapModule(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"create_iam_role_policy": false,
		},
		Logger:               logger.Discard,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{
			Operation:     testskeleton.ErrorContains,
			ExpectedValue: "minimum field size of 1, GetRoleInput.RoleName",
			Message:       "Minimum size of IAM role name should be 1",
		},
	}

	// plan only infrastructure to check if there are errors
	testskeleton.PlanInfraCheckErrors(t, terraformOptions, assertList, "Expecting error with invalid IAM role")
}

func TestOutputForModuleBootstrapWhileUsingExistingIamRoleForBootstrapModule(t *testing.T) {
	// define options for Terraform
	source := rand.NewSource(time.Now().UnixNano())
	random := rand.New(source)
	number := random.Intn(100)
	iamRoleNameCreatedForTests := fmt.Sprintf("terratest-integration-test-%d", number)
	fmt.Printf("Creating role for tests %s\n", iamRoleNameCreatedForTests)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"create_iam_role_policy": false,
			"iam_role_name":          iamRoleNameCreatedForTests,
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check role name
		{
			OutputName: "iam_role_name",
			Operation:  testskeleton.NotEmpty,
		},
		{
			OutputName:    "iam_role_name",
			Operation:     testskeleton.Equal,
			ExpectedValue: iamRoleNameCreatedForTests,
			Message:       "Role name is different from expected one",
		},

		// check role ARN
		{OutputName: "iam_role_arn", Operation: testskeleton.NotEmpty, ExpectedValue: nil},
		{
			OutputName:    "iam_role_arn",
			Operation:     testskeleton.StartsWith,
			ExpectedValue: "arn:aws:iam::",
			Message:       "Role ARN should start from arn:aws:iam::",
		},
	}

	// deploy test infrastructure and verify outputs and verify no changes are required after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}

func TestErrorForModuleBootstrapWhileProvidingInvalidDhcpSettingsForBootstrapModule(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"dhcp_send_hostname":          "invalid",
			"dhcp_send_client_id":         "invalid",
			"dhcp_accept_server_hostname": "invalid",
			"dhcp_accept_server_domain":   "invalid",
		},
		Logger:               logger.Discard,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{
			Operation:     testskeleton.ErrorContains,
			ExpectedValue: "The DHCP server determines a value of yes or no for variable",
			Message:       "The DHCP option's value should be yes or no",
		},
	}

	// plan only infrastructure to check if there are errors
	testskeleton.PlanInfraCheckErrors(t, terraformOptions, assertList, "Expecting errors with DHCP settings")
}
