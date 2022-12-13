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
	expectedManagedPrefixListEntries := []string{"10.241.0.0/16", "10.242.0.0/16", "10.251.0.0/16", "10.252.0.0/16"}
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	destinationCidrBlock := terraform.Output(t, terraformOptions, "destination_cidr_block")
	destinationManagedPrefixListId := terraform.Output(t, terraformOptions, "destination_managed_prefix_list_id")
	destinationManagedPrefixListEntries := terraform.Output(t, terraformOptions, "destination_managed_prefix_list_entries")
	mgmtTestVpcRouteMgmtEntries := terraform.OutputList(t, terraformOptions, "mgmt_test_vpc_route_mgmt_entries")

	// then
	assert.NotEmpty(t, destinationCidrBlock)
	assert.NotEmpty(t, destinationManagedPrefixListId)
	assert.NotEmpty(t, destinationManagedPrefixListEntries)
	assert.NotEmpty(t, mgmtTestVpcRouteMgmtEntries)
	assert.Equal(t, expectedManagedPrefixListEntries, mgmtTestVpcRouteMgmtEntries)
}
