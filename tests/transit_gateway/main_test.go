package transit_gateway

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/go/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleTransitGatewayFullVariables(t *testing.T) {
	// define options for Terraform
	tgwName := "tgw-"
	regionName := "us-east-1"
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_transit_gateway_",
			"region":      regionName,
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_id", Operation: testskeleton.NotEmpty},
		{OutputName: "tgw_id", Operation: testskeleton.StartsWith, ExpectedValue: tgwName, Message: "TGW ARN should starts from " + tgwName},

		{OutputName: "tgw_arn", Operation: testskeleton.NotEmpty},
		{OutputName: "tgw_arn", Operation: testskeleton.StartsWith, ExpectedValue: "arn:aws:ec2:" + regionName, Message: "TGW ID should starts from arn:aws:ec2:" + regionName},

		{OutputName: "tgw_route_tables", Operation: testskeleton.NotEmpty, ExpectedValue: nil},
		{OutputName: "tgw_route_tables", Operation: testskeleton.ListLengthEqual, ExpectedValue: 2},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}

func TestOutputForModuleTransitGatewayMinimumVariables(t *testing.T) {
	// variables used in Terraform options and assertions
	tgwName := "tgw-"
	regionName := "us-east-1"

	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_transit_gateway_",
			"region":      regionName,
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_id", Operation: testskeleton.NotEmpty},
		{OutputName: "tgw_id", Operation: testskeleton.StartsWith, ExpectedValue: tgwName, Message: "TGW ARN should starts from " + tgwName},

		{OutputName: "tgw_arn", Operation: testskeleton.NotEmpty},
		{OutputName: "tgw_arn", Operation: testskeleton.StartsWith, ExpectedValue: "arn:aws:ec2:" + regionName, Message: "TGW ID should starts from arn:aws:ec2:" + regionName},

		{OutputName: "tgw_route_tables", Operation: testskeleton.NotEmpty, ExpectedValue: nil},
		{OutputName: "tgw_route_tables", Operation: testskeleton.ListLengthEqual, ExpectedValue: 0},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
