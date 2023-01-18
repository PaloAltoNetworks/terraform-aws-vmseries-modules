package subnet_set

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleSubnetSet(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "availability_zones", Operation: "NotEmpty"},
		{OutputName: "availability_zones", Operation: "ListLengthEqual", ExpectedValue: 2},

		{OutputName: "route_tables", Operation: "NotEmpty"},
		{OutputName: "route_tables", Operation: "ListLengthEqual", ExpectedValue: 2},

		{OutputName: "subnet_names", Operation: "NotEmpty"},
		{OutputName: "subnet_names", Operation: "ListLengthEqual", ExpectedValue: 2},

		{OutputName: "subnets_cidrs", Operation: "NotEmpty"},
		{OutputName: "subnets_cidrs", Operation: "ListLengthEqual", ExpectedValue: 2},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
