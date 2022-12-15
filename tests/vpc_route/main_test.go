package bootstrap

import (
	"testing"

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
