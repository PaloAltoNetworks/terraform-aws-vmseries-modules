package transit_gateway_attachment

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleTransitGatewayAttachmentFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_tgw_attach_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_id", Operation: "NotEmpty"},
		{OutputName: "tgw_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},

		{OutputName: "tgw_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:us-east-1", Message: "TGW ARN should starts from arn:aws:ec2:us-east-1"},

		{OutputName: "tgw_route_tables", Operation: "NotEmpty"},
		{OutputName: "tgw_route_tables", Operation: "ListLengthEqual", ExpectedValue: 2},

		{OutputName: "tgw_attachment_next_hop_set", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "tgw_attachment_next_hop_set_tgw_id", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "tgw_attachment_next_hop_set_tgw_id", Operation: "NotEmpty", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}

func TestOutputForModuleTransitGatewayAttachmentMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_tgw_attach_",
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

		{OutputName: "tgw_route_tables", Operation: "NotEmpty"},
		{OutputName: "tgw_route_tables", Operation: "ListLengthEqual", ExpectedValue: 0},

		{OutputName: "tgw_attachment_next_hop_set", Operation: "NotFound"},
		{OutputName: "tgw_attachment_next_hop_set_tgw_id", Operation: "NotFound"},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
