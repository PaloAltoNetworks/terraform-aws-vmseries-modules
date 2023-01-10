package bootstrap

import (
	"fmt"
	"math/rand"
	"testing"
	"time"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModuleBootstrapWhileCreatingIamRoleForBootstrapModule(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:         ".",
		Vars:                 map[string]interface{}{},
		Logger:               logger.Discard,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check role name
		{OutputName: "iam_role_name", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "iam_role_name", Operation: "StartsWith", ExpectedValue: "a", Message: "Role name should start from a"},

		// check role ARN
		{OutputName: "iam_role_arn", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "iam_role_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:iam::", Message: "Role ARN should start from arn:aws:iam::"},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}

// func TestErrorForModuleBootstrapWhileNotCreatingIamRoleAndNotPassingIamRoleNameForBootstrapModule(t *testing.T) {
// 	// given
// 	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
// 		TerraformDir: ".",
// 		Vars: map[string]interface{}{
// 			"switchme":               false,
// 			"create_iam_role_policy": false,
// 		},
// 		Logger:  logger.Discard,
// 		Lock:    true,
// 		Upgrade: true,
// 	})

// 	// when
// 	if _, err := terraform.InitAndPlanE(t, terraformOptions); err != nil {
// 		// then
// 		assert.Error(t, err)
// 	} else {
// 		// then
// 		t.Error("Expecting error: data.aws_iam_role.this is empty tuple")
// 	}
// }

func TestOutputForModuleBootstrapWhileUsingExistingIamRoleForBootstrapModule(t *testing.T) {
	// define options for Terraform
	source := rand.NewSource(time.Now().UnixNano())
	random := rand.New(source)
	number := random.Intn(100)
	iamRoleNameCreatedForTests := fmt.Sprintf("terratest-integration-test-%d", number)
	fmt.Printf("Creating role for tests %s\n", iamRoleNameCreatedForTests)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"create_iam_role_policy": false,
			"iam_role_name":          iamRoleNameCreatedForTests,
		},
		Logger:               logger.Discard,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// check role name
		{OutputName: "iam_role_name", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "iam_role_name", Operation: "Equal", ExpectedValue: iamRoleNameCreatedForTests, Message: "Role name is different from expected one"},

		// check role ARN
		{OutputName: "iam_role_arn", Operation: "NotEmpty", ExpectedValue: nil},
		{OutputName: "iam_role_arn", Operation: "StartsWith", ExpectedValue: "arn:aws:iam::", Message: "Role ARN should start from arn:aws:iam::"},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}

// func TestErrorForModuleBootstrapWhileProvidingInvalidDhcpSettingsForBootstrapModule(t *testing.T) {
// 	// given
// 	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
// 		TerraformDir: ".",
// 		Vars: map[string]interface{}{
// 			"switchme":                    false,
// 			"dhcp_send_hostname":          "invalid",
// 			"dhcp_send_client_id":         "invalid",
// 			"dhcp_accept_server_hostname": "invalid",
// 			"dhcp_accept_server_domain":   "invalid",
// 		},
// 		Logger:  logger.Discard,
// 		Lock:    true,
// 		Upgrade: true,
// 	})

// 	// when
// 	if _, err := terraform.InitAndPlanE(t, terraformOptions); err != nil {
// 		// then
// 		assert.Error(t, err)
// 	} else {
// 		// then
// 		t.Error("Expecting errors with DHCP settings")
// 	}
// }
