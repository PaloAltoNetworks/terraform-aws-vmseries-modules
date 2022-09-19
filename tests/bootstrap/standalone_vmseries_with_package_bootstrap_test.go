package bootstrap

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputsForCsvBasicExampleAndForVmSeries(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/standalone_vmseries_with_package_bootstrap/",
		VarFiles:     []string{"../../examples/standalone_vmseries_with_package_bootstrap/example.tfvars"},
		Logger:       logger.Discard,
		Lock:         true,
		Upgrade:      true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)

	// then
}
