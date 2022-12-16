package bootstrap

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamples(t *testing.T) {
	testCases := []struct {
		Name             string
		TerraformDir     string
		TerraformVarFile string
	}{
		{
			Name:             "standalone_vmseries_with_userdata_bootstrap",
			TerraformDir:     "../../examples/standalone_vmseries_with_userdata_bootstrap",
			TerraformVarFile: "../../tests/examples/standalone_vmseries_with_userdata_bootstrap.tfvars",
		},
		{
			Name:             "standalone_panorama",
			TerraformDir:     "../../examples/standalone_panorama",
			TerraformVarFile: "../../tests/examples/standalone_panorama.tfvars",
		},
		{
			Name:             "asg",
			TerraformDir:     "../../examples/asg",
			TerraformVarFile: "../../tests/examples/asg.tfvars",
		},
		{
			Name:             "tgw_inbound_combined_with_gwlb",
			TerraformDir:     "../../examples/tgw_inbound_combined_with_gwlb",
			TerraformVarFile: "../../tests/examples/tgw_inbound_combined_with_gwlb.tfvars",
		},
		{
			Name:             "tgw_inbound_with_alb_nlb",
			TerraformDir:     "../../examples/tgw_inbound_with_alb_nlb",
			TerraformVarFile: "../../tests/examples/tgw_inbound_with_alb_nlb.tfvars",
		},
		{
			Name:             "transit_gateway_peering",
			TerraformDir:     "../../examples/transit_gateway_peering",
			TerraformVarFile: "../../tests/examples/transit_gateway_peering.tfvars",
		},
		{
			Name:             "vmseries_combined_with_gwlb_natgw",
			TerraformDir:     "../../examples/vmseries_combined_with_gwlb_natgw",
			TerraformVarFile: "../../tests/examples/vmseries_combined_with_gwlb_natgw.tfvars",
		},
		{
			Name:             "vpc_endpoint",
			TerraformDir:     "../../examples/vpc_endpoint",
			TerraformVarFile: "../../tests/examples/vpc_endpoint.tfvars",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.Name, func(t *testing.T) {
			// t.Parallel()
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:       tc.TerraformDir,
				Logger:             logger.Default,
				Lock:               true,
				Upgrade:            true,
				MaxRetries:         3,
				TimeBetweenRetries: 15 * time.Second,
				VarFiles:           []string{tc.TerraformVarFile},
			})
			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)
		})
	}
}
