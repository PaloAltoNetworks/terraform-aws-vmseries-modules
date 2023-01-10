package testskeleton

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Structure used to assert each output value
// by comparing it to expected value using defined operation.
type AssertExpression struct {
	OutputName    string
	Operation     string
	ExpectedValue interface{}
	Message       string
}

// Function is responsible for deploy infrastructure,
// verify assert expressions and destroy infrastructure
func DeployInfraCheckOutputs(t *testing.T, terraformOptions *terraform.Options, assertList []AssertExpression) *terraform.Options {
	// If no Terraform options were provided, use default one
	if terraformOptions == nil {
		terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: ".",
			Logger:       logger.Default,
			Lock:         true,
			Upgrade:      true,
		})
	}

	// Always destroy infrastructure, even if any assert expression fails
	destroyFunc := func() {
		terraform.Destroy(t, terraformOptions)
	}
	defer destroyFunc()

	// Terraform initalization and apply with auto-approve
	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs and compare to expected results
	AssertOutputs(t, terraformOptions, assertList)

	return terraformOptions
}

// Function is comparing every provided output in expressions lists
// and checks value using expression defined in the list
func AssertOutputs(t *testing.T, terraformOptions *terraform.Options, assertList []AssertExpression) {
	for _, assertExpression := range assertList {
		switch assertExpression.Operation {
		case "NotEmpty":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.NotEmpty(t, outputValue, assertExpression.Message)
		case "Empty":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.Empty(t, outputValue, assertExpression.Message)
		case "Equal":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.Equal(t, assertExpression.ExpectedValue, outputValue, assertExpression.Message)
		case "ListLengthEqual":
			outputValue := terraform.OutputList(t, terraformOptions, assertExpression.OutputName)
			assert.Equal(t, assertExpression.ExpectedValue, len(outputValue), assertExpression.Message)
		case "StartsWith":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.True(t, strings.HasPrefix(outputValue, fmt.Sprintf("%v", assertExpression.ExpectedValue)), assertExpression.Message)
		// other case needs to be added while working on tests for modules
		// ... TODO ...
		default:
			logger.Logf(t, "Unknown operation used in assert expressions list")
			t.Fail()
		}
	}
}
