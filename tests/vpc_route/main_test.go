package bootstrap

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputWhileCreatingManagedPrefixListForVpcRouteModule(t *testing.T) {
	var terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"name_prefix": "terratest_vpc_route_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})
	var assertList = []testskeleton.AssertExpression{
		{OutputName: "routes_cidr", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_mpl", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_cidr", Operation: "Equal", ExpectedValue: "[10.251.0.0/16 10.252.0.0/16]"},
		{OutputName: "routes_mpl", Operation: "ListLengthEqual", ExpectedValue: 1},
	}
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
