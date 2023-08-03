package vpc_plan

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-modules-vmseries-tests-skeleton/pkg/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestNoErrorInPlanForModuleVpc(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:         ".",
		Vars:                 map[string]interface{}{},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{}

	// deploy test infrastructure and verify outputs
	testskeleton.PlanInfraCheckErrors(t, terraformOptions, assertList, "No errors are expected")
}
