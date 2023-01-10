package bootstrap

import (
	"fmt"
	"math/rand"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestOutputWhileCreatingIamRoleForBootstrapModule(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars:         map[string]interface{}{},
		Logger:       logger.Discard,
		Lock:         true,
		Upgrade:      true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	iamRoleName := terraform.Output(t, terraformOptions, "iam_role_name")
	iamRoleArn := terraform.Output(t, terraformOptions, "iam_role_arn")

	// then
	assert.NotEmpty(t, iamRoleName)
	assert.NotEmpty(t, iamRoleArn)
	assert.True(t, strings.HasPrefix(iamRoleName, "a"))
	assert.True(t, strings.HasPrefix(iamRoleArn, "arn:aws:iam::"))
}

func TestErrorWhileNotCreatingIamRoleAndNotPassingIamRoleNameForBootstrapModule(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"create_iam_role_policy": false,
		},
		Logger:  logger.Discard,
		Lock:    true,
		Upgrade: true,
	})

	// when
	if _, err := terraform.InitAndPlanE(t, terraformOptions); err != nil {
		// then
		assert.Error(t, err)
	} else {
		// then
		t.Error("Expecting error: data.aws_iam_role.this is empty tuple")
	}
}

func TestOutputWhileUsingExistingIamRoleForBootstrapModule(t *testing.T) {
	// given
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
		Logger:  logger.Discard,
		Lock:    true,
		Upgrade: true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	iamRoleName := terraform.Output(t, terraformOptions, "iam_role_name")
	iamRoleArn := terraform.Output(t, terraformOptions, "iam_role_arn")

	// then
	assert.NotEmpty(t, iamRoleName)
	assert.NotEmpty(t, iamRoleArn)
	assert.Equal(t, iamRoleName, iamRoleNameCreatedForTests)
	assert.True(t, strings.HasPrefix(iamRoleArn, "arn:aws:iam::"))
}

func TestErrorWhileProvidingInvalidDhcpSettingsForBootstrapModule(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"dhcp_send_hostname":          "invalid",
			"dhcp_send_client_id":         "invalid",
			"dhcp_accept_server_hostname": "invalid",
			"dhcp_accept_server_domain":   "invalid",
		},
		Logger:  logger.Discard,
		Lock:    true,
		Upgrade: true,
	})

	// when
	if _, err := terraform.InitAndPlanE(t, terraformOptions); err != nil {
		// then
		assert.Error(t, err)
	} else {
		// then
		t.Error("Expecting errors with DHCP settings")
	}
}
