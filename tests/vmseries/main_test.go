package vmseries

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/helpers"
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleVmseriesWithMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_vmseries_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check VM-Series URL
		{
			OutputName: "vmseries_url",
			Operation:  "NotEmpty",
		},
		// check access to login page in web UI for VM-Series
		{
			Operation:  "CheckFunctionWithOutput",
			Check:      helpers.CheckHttpGetWebApp,
			OutputName: "vmseries_url",
			Message:    "After bootstrapping, which takes few minutes, web UI for VM-Series should be accessible",
		},
		// check access via SSH to VM-Series
		{
			Operation:  "CheckFunctionWithOutput",
			Check:      helpers.CheckTcpPortOpened,
			OutputName: "vmseries_ssh",
			Message:    "After bootstrapping, which takes few minutes, SSH for VM-Series should be accessible",
		},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
