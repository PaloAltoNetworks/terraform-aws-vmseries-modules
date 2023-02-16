package vmseries

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/helpers"
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	tfjson "github.com/hashicorp/terraform-json"
)

func TestOutputForModuleVmseriesWithFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
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
			Operation:  testskeleton.NotEmpty,
		},
		// check VM-Series SSH
		{
			OutputName: "vmseries_ssh",
			Operation:  testskeleton.NotEmpty,
		},
		// check access to login page in web UI for VM-Series
		{
			Operation:  testskeleton.CheckFunctionWithOutput,
			Check:      helpers.CheckHttpGetWebApp,
			OutputName: "vmseries_url",
			Message:    "After bootstrapping, which takes few minutes, web UI for VM-Series should be accessible",
		},
		// check access via SSH to VM-Series
		{
			Operation:  testskeleton.CheckFunctionWithOutput,
			Check:      helpers.CheckTcpPortOpened,
			OutputName: "vmseries_ssh",
			Message:    "After bootstrapping, which takes few minutes, SSH for VM-Series should be accessible",
		},
	}

	// prepare additional changes deployed after
	additionalChangesAfterDeployment := testskeleton.AdditionalChangesAfterDeployment{
		AdditionalVarsValues: map[string]interface{}{
			"name_sufix": "_terratest",
		},
		FileNameWithTfCode: "resources.tf.temp",
		ChangedResources: []testskeleton.ChangedResource{
			{
				Name:   "module.vmseries[\"vmseries01\"].aws_network_interface.this[\"mgmt\"]",
				Action: tfjson.ActionUpdate,
			},
			{
				Name:   "module.vmseries[\"vmseries01\"].aws_eip.this[\"mgmt\"]",
				Action: tfjson.ActionUpdate,
			},
			{
				Name:   "module.vmseries[\"vmseries01\"].aws_instance.this",
				Action: tfjson.ActionUpdate,
			},
			{
				Name:   "module.panorama_vpc_routes[\"mgmt_10.80.10.0/24\"].aws_route.this[\"us-east-1a\"]",
				Action: tfjson.ActionCreate,
			},
		},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChangesDeployChanges(t, terraformOptions, assertList, &additionalChangesAfterDeployment)
}

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
		{
			Operation:     testskeleton.ErrorContains,
			ExpectedValue: "No value for required variable",
			Message:       "3 variables are required: vmseries, vmseries_version, bootstrap_options",
		},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.PlanInfraCheckErrors(t, terraformOptions, assertList, "VM-Series plan deployment should fail without VM-Series configuration")
}

func TestOutputForModuleVmseriesWithFullVariablesWithS3Bootstrapping(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix":                "terratest_module_vmseries_",
			"use_s3_bucket_to_bootstrap": true,
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
			Operation:  testskeleton.NotEmpty,
		},
		// check VM-Series SSH
		{
			OutputName: "vmseries_ssh",
			Operation:  testskeleton.NotEmpty,
		},
		// check access to login page in web UI for VM-Series
		{
			Operation:  testskeleton.CheckFunctionWithOutput,
			Check:      helpers.CheckHttpGetWebApp,
			OutputName: "vmseries_url",
			Message:    "After bootstrapping, which takes few minutes, web UI for VM-Series should be accessible",
		},
		// check access via SSH to VM-Series
		{
			Operation:  testskeleton.CheckFunctionWithOutput,
			Check:      helpers.CheckTcpPortOpened,
			OutputName: "vmseries_ssh",
			Message:    "After bootstrapping, which takes few minutes, SSH for VM-Series should be accessible",
		},
	}

	// prepare additional changes deployed after
	additionalChangesAfterDeployment := testskeleton.AdditionalChangesAfterDeployment{
		AdditionalVarsValues: map[string]interface{}{
			"override_and_disable_mgmt_create_public_ip": true,
		},
		FileNameWithTfCode: "",
		ChangedResources: []testskeleton.ChangedResource{
			{
				Name:   "module.vmseries[\"vmseries01\"].aws_eip.this[\"mgmt\"]",
				Action: tfjson.ActionDelete,
			},
		},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChangesDeployChanges(t, terraformOptions, assertList, &additionalChangesAfterDeployment)
}
