package bootstrap

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleVpcRoute(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_vpc_route_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check destination type ipv4
		{OutputName: "routes_cidr", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_cidr", Operation: "Equal", ExpectedValue: "[10.231.0.0/16 10.232.0.0/16 10.251.0.0/16 10.252.0.0/16]"},

		// check destination type mpl
		{OutputName: "routes_mpl", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_mpl", Operation: "ListLengthEqual", ExpectedValue: 1},

		// check next hop transit_gateway
		{OutputName: "routes_next_hop_transit_gateway", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_transit_gateway", Operation: "ListLengthEqual", ExpectedValue: 2},

		// check next hop internet_gateway
		{OutputName: "routes_next_hop_gateway", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_gateway", Operation: "ListLengthEqual", ExpectedValue: 3},

		// check next hop nat_gateway
		{OutputName: "routes_next_hop_nat_gateway", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_nat_gateway", Operation: "ListLengthEqual", ExpectedValue: 12},

		// check next hop interface
		{OutputName: "routes_next_hop_network_interface", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_network_interface", Operation: "ListLengthEqual", ExpectedValue: 2},

		// check next hop vpc_endpoint
		{OutputName: "routes_next_hop_vpc_endpoint", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_vpc_endpoint", Operation: "ListLengthEqual", ExpectedValue: 2},

		// check next hop vpc_peer
		{OutputName: "routes_next_hop_vpc_peering_connection", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_vpc_peering_connection", Operation: "ListLengthEqual", ExpectedValue: 2},

		// check next hop egress_only_gateway
		{OutputName: "routes_next_hop_egress_only_gateway", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_egress_only_gateway", Operation: "ListLengthEqual", ExpectedValue: 0},

		// check next hop local_gateway
		{OutputName: "routes_next_hop_local_gateway", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "routes_next_hop_local_gateway", Operation: "ListLengthEqual", ExpectedValue: 0},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
