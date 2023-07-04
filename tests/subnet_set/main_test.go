package subnet_set

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/go/testskeleton"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleSubnetSet(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		{OutputName: "availability_zones", Operation: testskeleton.NotEmpty},
		{OutputName: "availability_zones", Operation: testskeleton.ListLengthEqual, ExpectedValue: 2},

		{OutputName: "route_tables", Operation: testskeleton.NotEmpty},
		{OutputName: "route_tables", Operation: testskeleton.ListLengthEqual, ExpectedValue: 2},

		{OutputName: "subnet_names", Operation: testskeleton.NotEmpty},
		{OutputName: "subnet_names", Operation: testskeleton.ListLengthEqual, ExpectedValue: 2},

		{OutputName: "subnets_cidrs", Operation: testskeleton.NotEmpty},
		{OutputName: "subnets_cidrs", Operation: testskeleton.ListLengthEqual, ExpectedValue: 2},
	}

	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptions, assertList)
}
