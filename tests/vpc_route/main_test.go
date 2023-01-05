package bootstrap

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestOutputWhileCreatingManagedPrefixListForVpcRouteModule(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	routesCidr := terraform.OutputList(t, terraformOptions, "routes_cidr")
	routesMpl := terraform.OutputList(t, terraformOptions, "routes_mpl")

	// then
	assert.NotEmpty(t, routesCidr)
	assert.NotEmpty(t, routesMpl)
	assert.Equal(t, 2, len(routesCidr))
	assert.Equal(t, 1, len(routesMpl))
}

func TestModuleOutputs(t *testing.T) {
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
