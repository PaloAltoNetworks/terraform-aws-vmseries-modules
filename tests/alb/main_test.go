package main

import (
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/helpers"
	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"log"
	"testing"
)

func TestALBOutputAndConectivitiyWithFullTFVars(t *testing.T) {

	// define variables for Terraform
	namePrefix := "terratest-alb-"

	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	destroyFunc := func() {
		terraform.Destroy(t, terraformOptions)
	}
	defer destroyFunc()
	terraformOptions = testskeleton.InitAndApplyOnlyWithoutDelete(t, terraformOptions)

	albName := terraform.Output(t, terraformOptions, "alb_name")
	log.Printf("Alb_name = %s", albName)

	assertList := []testskeleton.AssertExpression{
		// check if the ALB is created with correct FQDN
		{
			OutputName: "alb_name",
			Operation:  "NotEmpty",
		},
		// check if the ALB is created with correct FQDN
		{
			OutputName:    "alb_name",
			Operation:     "StartsWith",
			ExpectedValue: namePrefix,
		},
		// check communication with app
		{
			Operation:   "CheckFunctionWithValue",
			Check:       helpers.CheckHttpGetWebUiLoginPage,
			TestedValue: "http://" + albName + "/",
		},
	}
	testskeleton.AssertOutputs(t, terraformOptions, assertList)

}

func TestALBOutputWithMinimumTFVars(t *testing.T) {

	// define variables for Terraform
	namePrefix := "terratest-alb-"
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})
	assertList := []testskeleton.AssertExpression{
		// check if the ALB is created with correct FQDN
		{
			OutputName: "alb_name",
			Operation:  "NotEmpty",
		},
		// check if the ALB is created with correct FQDN
		{
			OutputName:    "alb_name",
			Operation:     "StartsWith",
			ExpectedValue: namePrefix,
		},
	}
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
