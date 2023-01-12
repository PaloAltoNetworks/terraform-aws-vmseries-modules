package bootstrap

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleTransitGatewayFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_transit_gateway_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_id", Operation: "NotEmpty"},
		{OutputName: "tgw_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ARN should starts from tgw-"},

		{OutputName: "tgw_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:us-east-1", Message: "TGW ID should starts from arn:aws:ec2:us-east-1"},

		{OutputName: "tgw_route_tables", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "tgw_route_tables", Operation: "ListLengthEqual", ExpectedValue: 2},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}

func TestOutputForModuleTransitGatewayMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_transit_gateway_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_id", Operation: "NotEmpty"},
		{OutputName: "tgw_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ARN should starts from tgw-"},

		{OutputName: "tgw_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:us-east-1", Message: "TGW ID should starts from arn:aws:ec2:us-east-1"},

		{OutputName: "tgw_route_tables", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "tgw_route_tables", Operation: "ListLengthEqual", ExpectedValue: 0},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
