package transit_gateway_peering

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleTransitGatewayPeeringFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_tgw_peer_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_local_id", Operation: "NotEmpty"},
		{OutputName: "tgw_local_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},

		{OutputName: "tgw_local_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_local_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:", Message: "TGW ARN should starts from arn:aws:ec2:"},

		{OutputName: "tgw_remote_id", Operation: "NotEmpty"},
		{OutputName: "tgw_remote_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},

		{OutputName: "tgw_remote_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_remote_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:", Message: "TGW ARN should starts from arn:aws:ec2:"},

		{OutputName: "route_destination_from_remote_spoke_to_local_region", Operation: "NotEmpty"},
		{OutputName: "route_destination_from_remote_spoke_to_local_region", Operation: "Equal", ExpectedValue: "10.0.0.0/8"},

		{OutputName: "route_destination_from_local_security_to_remote_region", Operation: "NotEmpty"},
		{OutputName: "route_destination_from_local_security_to_remote_region", Operation: "Equal", ExpectedValue: "10.244.0.0/16"},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}

func TestOutputForModuleTransitGatewayPeeringMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_tgw_peer_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "tgw_local_id", Operation: "NotEmpty"},
		{OutputName: "tgw_local_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},

		{OutputName: "tgw_local_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_local_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:", Message: "TGW ARN should starts from arn:aws:ec2:"},

		{OutputName: "tgw_remote_id", Operation: "NotEmpty"},
		{OutputName: "tgw_remote_id", Operation: "StartsWith", ExpectedValue: "tgw-", Message: "TGW ID should starts from tgw-"},

		{OutputName: "tgw_remote_arn", Operation: "NotEmpty"},
		{OutputName: "tgw_remote_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:ec2:", Message: "TGW ARN should starts from arn:aws:ec2:"},

		{OutputName: "route_destination_from_remote_spoke_to_local_region", Operation: "NotEmpty"},
		{OutputName: "route_destination_from_remote_spoke_to_local_region", Operation: "Equal", ExpectedValue: "10.0.0.0/8"},

		{OutputName: "route_destination_from_local_security_to_remote_region", Operation: "NotEmpty"},
		{OutputName: "route_destination_from_local_security_to_remote_region", Operation: "Equal", ExpectedValue: "10.244.0.0/16"},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
