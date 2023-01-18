package testskeleton

import (
	"fmt"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Sometimes there is a need to execute custom function to check something,
// so then in assert expression we need to provide function, which results is compared to true
type CheckFunction func(t *testing.T, outputValue string) bool

// Structure used to assert each output value
// by comparing it to expected value using defined operation.
type AssertExpression struct {
	OutputName    string
	Operation     string
	ExpectedValue interface{}
	Message       string
	Check         CheckFunction
	TestedValue   string
}

// Function is responsible for deployment of the infrastructure,
// verify assert expressions and destroy infrastructure
func DeployInfraCheckOutputs(t *testing.T, terraformOptions *terraform.Options, assertList []AssertExpression) *terraform.Options {
	return GenericDeployInfraAndVerifyAssertChanges(t, terraformOptions, assertList, false, true)
}

// Function is responsible for deployment of the infrastructure, verify assert expressions,
// verify if there are no changes in plan after deployment and destroy infrastructure
func DeployInfraCheckOutputsVerifyChanges(t *testing.T, terraformOptions *terraform.Options, assertList []AssertExpression) *terraform.Options {
	return GenericDeployInfraAndVerifyAssertChanges(t, terraformOptions, assertList, true, true)
}

// Function is responsible only for deployment of the infrastructure,
// no verification of assert expressions and no destroyment of the infrastructure
func DeployInfraNoCheckOutputsNoDestroy(t *testing.T, terraformOptions *terraform.Options) *terraform.Options {
	return GenericDeployInfraAndVerifyAssertChanges(t, terraformOptions, nil, false, false)
}

// Generic deployment function used in wrapper functions above
func GenericDeployInfraAndVerifyAssertChanges(t *testing.T, terraformOptions *terraform.Options,
	assertList []AssertExpression, checkNoChanges bool, destroyInfraAtEnd bool) *terraform.Options {
	// If no Terraform options were provided, use default one
	if terraformOptions == nil {
		terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: ".",
			Logger:       logger.Default,
			Lock:         true,
			Upgrade:      true,
		})
	}

	// Destroy infrastructure, even if any assert expression fails
	if destroyInfraAtEnd {
		destroyFunc := func() {
			terraform.Destroy(t, terraformOptions)
		}
		defer destroyFunc()
	}

	// Terraform initalization and apply with auto-approve
	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs and compare to expected results
	if assertList != nil && len(assertList) > 0 {
		AssertOutputs(t, terraformOptions, assertList)
	}

	// Check if there are no changes planed after deployment (if checkNoChanges is true)
	if checkNoChanges {
		output := terraform.InitAndPlan(t, terraformOptions)
		noInfraChangeExpectedMessage := "No changes in infrastructure are expected after deployment"
		assert.Regexp(t, regexp.MustCompile(".*No changes.*Your infrastructure matches the configuration.*"), output, noInfraChangeExpectedMessage)
		assert.NotRegexp(t, regexp.MustCompile(".*Plan:.*to add,.*to change,.*to destroy.*"), output, noInfraChangeExpectedMessage)
	}

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
		case "NotFound":
			_, err := terraform.OutputE(t, terraformOptions, assertExpression.OutputName)
			assert.ErrorContains(t, err,
				fmt.Sprintf("Output \"%v\" not found", assertExpression.OutputName),
				assertExpression.Message)
		case "ListLengthEqual":
			outputValue := terraform.OutputList(t, terraformOptions, assertExpression.OutputName)
			assert.Equal(t, assertExpression.ExpectedValue, len(outputValue), assertExpression.Message)
		case "StartsWith":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.True(t, strings.HasPrefix(outputValue,
				fmt.Sprintf("%v", assertExpression.ExpectedValue)),
				assertExpression.Message)
		case "CheckFunctionWithOutput":
			outputValue := terraform.Output(t, terraformOptions, assertExpression.OutputName)
			assert.True(t, assertExpression.Check(t, outputValue), assertExpression.Message)
		case "CheckFunctionWithValue":
			assert.True(t, assertExpression.Check(t, assertExpression.TestedValue), assertExpression.Message)
		case "EqualToValue":
			assert.Equal(t, assertExpression.TestedValue, assertExpression.ExpectedValue)
		// other case needs to be added while working on tests for modules
		// ... TODO ...
		default:
			tLogger := logger.Logger{}
			tLogger.Logf(t, "Unknown operation used in assert expressions list")
			t.Fail()
		}
	}
}

// Functions is response for planning deployment,
// verify errors expressions (no changes are deployed)
func PlanInfraCheckErrors(t *testing.T, terraformOptions *terraform.Options,
	assertList []AssertExpression, noErrorsMessage string) *terraform.Options {
	// If no Terraform options were provided, use default one
	if terraformOptions == nil {
		terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: ".",
			Logger:       logger.Default,
			Lock:         true,
			Upgrade:      true,
		})
	}

	// Terraform initalization and plan
	if _, err := terraform.InitAndPlanE(t, terraformOptions); err != nil {
		// Verify errors and compare to expected results
		assert.Error(t, err)
		AssertErrors(t, err, assertList)
	} else {
		// Fail test, if errors were expected
		if len(assertList) > 0 {
			t.Error(noErrorsMessage)
		}
	}

	return terraformOptions
}

// Function is comparing every provided error in expressions lists
// and checks value using expression defined in the list
func AssertErrors(t *testing.T, err error, assertList []AssertExpression) {
	for _, assertExpression := range assertList {
		switch assertExpression.Operation {
		case "ErrorContains":
			assert.ErrorContains(t, err,
				fmt.Sprintf("%v", assertExpression.ExpectedValue),
				assertExpression.Message)
		// other case needs to be added while working on tests for modules
		// ... TODO ...
		default:
			tLogger := logger.Logger{}
			tLogger.Logf(t, "Unknown operation used in assert expressions list")
			t.Fail()
		}
	}
}
