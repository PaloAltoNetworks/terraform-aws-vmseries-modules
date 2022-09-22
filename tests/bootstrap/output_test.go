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
		// VarFiles:     []string{"../../examples/standalone_vmseries_with_package_bootstrap/example.tfvars"},
		Vars: map[string]interface{}{
			"switchme": false,
		},
		Logger:  logger.Discard,
		Lock:    true,
		Upgrade: true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	iam_role_name := terraform.Output(t, terraformOptions, "iam_role_name")
	iam_role_arn := terraform.Output(t, terraformOptions, "iam_role_arn")

	// then
	assert.NotEmpty(t, iam_role_name)
	assert.NotEmpty(t, iam_role_arn)
	assert.True(t, strings.HasPrefix(iam_role_name, "a"))
	assert.True(t, strings.HasPrefix(iam_role_arn, "arn:aws:iam::"))
}

func TestErrorWhileNotCreatingIamRoleAndNotPassingIamRoleNameForBootstrapModule(t *testing.T) {
	// given
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"switchme":               false,
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
	iam_role_name_created_for_tests := fmt.Sprintf("terratest-integration-test-%d", number)
	fmt.Printf("Creating role for tests %s\n", iam_role_name_created_for_tests)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{}{
			"switchme":               false,
			"create_iam_role_policy": false,
			"iam_role_name":          iam_role_name_created_for_tests,
		},
		Logger:  logger.Discard,
		Lock:    true,
		Upgrade: true,
	})
	defer terraform.Destroy(t, terraformOptions)

	// when
	terraform.InitAndApply(t, terraformOptions)
	iam_role_name := terraform.Output(t, terraformOptions, "iam_role_name")
	iam_role_arn := terraform.Output(t, terraformOptions, "iam_role_arn")

	// then
	assert.NotEmpty(t, iam_role_name)
	assert.NotEmpty(t, iam_role_arn)
	assert.Equal(t, iam_role_name, iam_role_name_created_for_tests)
	assert.True(t, strings.HasPrefix(iam_role_arn, "arn:aws:iam::"))
}
