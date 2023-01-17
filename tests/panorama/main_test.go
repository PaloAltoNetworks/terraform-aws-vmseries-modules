package bootstrap

import (
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/helpers"
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
)

func TestOutputForModulePanoramaWithFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_panorama_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check Panorama URL
		{
			OutputName: "panorama_url",
			Operation:  "NotEmpty",
		},
		// check access to login page in web UI for Panorama
		{
			Operation:  "CheckFunctionWithOutput",
			Check:      helpers.CheckHttpGetWebUiLoginPage,
			OutputName: "panorama_url",
			Message:    "After bootstrapping, which takes few minutes, web UI for Panorama should be accessible",
		},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}

func TestOutputForModulePanoramaWithMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_panorama_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check Panorama URL
		{
			OutputName: "panorama_url",
			Operation:  "NotEmpty",
		},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
