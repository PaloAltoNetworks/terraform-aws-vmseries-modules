package vpc_deployment

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleVpc(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:         ".",
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "vpc_cidr_block_correct", Operation: "NotEmpty"},
		{OutputName: "vpc_cidr_block_correct", Operation: "Equal", ExpectedValue: "10.0.0.0/16"},

		{OutputName: "vpc_read_cidr_block_correct", Operation: "NotEmpty"},
		{OutputName: "vpc_read_cidr_block_correct", Operation: "Equal", ExpectedValue: "10.0.0.0/16"},

		{OutputName: "vpc_read_igw_create_cidr_block_correct", Operation: "NotEmpty"},
		{OutputName: "vpc_read_igw_create_cidr_block_correct", Operation: "Equal", ExpectedValue: "10.0.0.0/16"},

		{OutputName: "vpc_read_igw_read_cidr_block_correct", Operation: "NotEmpty"},
		{OutputName: "vpc_read_igw_read_cidr_block_correct", Operation: "Equal", ExpectedValue: "10.0.0.0/16"},

		{OutputName: "is_vpc_name_correct", Operation: "Equal", ExpectedValue: "true"},
		{OutputName: "is_vpc_read_igw_create_name_correct", Operation: "Equal", ExpectedValue: "true"},
		{OutputName: "is_vpc_read_igw_read_name_correct", Operation: "Equal", ExpectedValue: "true"},
		{OutputName: "is_vpc_read_name_correct", Operation: "Equal", ExpectedValue: "true"},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
