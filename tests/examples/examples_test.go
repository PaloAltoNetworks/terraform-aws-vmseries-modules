package bootstrap

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDeploymentStandaloneVmseriesWithUserdataBootstrap(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/standalone_vmseries_with_userdata_bootstrap",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/standalone_vmseries_with_userdata_bootstrap.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentStandalonePanorama(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/standalone_panorama",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/standalone_panorama.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentAsg(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/asg",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/asg.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentTgwInboundCombinedWithGwlb(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/tgw_inbound_combined_with_gwlb",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/tgw_inbound_combined_with_gwlb.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentTgwInboundWithAlbNlb(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/tgw_inbound_with_alb_nlb",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/tgw_inbound_with_alb_nlb.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentTransitGatewayPeering(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/transit_gateway_peering",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/transit_gateway_peering.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentVmseriesCombinedWithGwlbNatgw(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/vmseries_combined_with_gwlb_natgw",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/vmseries_combined_with_gwlb_natgw.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestDeploymentVpcEdnpoint(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/vpc_endpoint",
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
		VarFiles:     []string{"../../tests/examples/vpc_endpoint.tfvars"},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
