// Generic utility that runs the terratest (tt), so that various test cases in this entire repository would behave similarly with minimal code duplication.
package generictt

import (
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// CheckFunc is a function that can be run on an applied Terraform test-case as given by t.
// The terraformOptions should be the same which were used to apply t.
// The function should either exit cleanly, or invoke t.Errorf() which fails the entire test-case in a usual way.
type CheckFunc func(t *testing.T, terraformOptions *terraform.Options)

// GenericTest runs the Terratest with generic settings.
func GenericTest(t *testing.T, terraformOptions *terraform.Options, checkFunc CheckFunc) *terraform.Options {
	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	if terraformOptions == nil {
		terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: ".",

			// Variables to pass to our Terraform code using -var options
			Vars: map[string]interface{}{
				"switchme": "true",
			},
		})
	}

	if checkFunc == nil {
		checkFunc = func(t *testing.T, terraformOptions *terraform.Options) { /* noop */ }
	}

	// Schedule `terraform destroy` at the end of the test, to clean up the created resources.
	destroyFunc := func() {
		logger.Log(t, "#################### End of logs for the Apply. Cleaning up now. ####################")
		terraform.Destroy(t, terraformOptions)
	}
	defer destroyFunc()

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)
	CheckOutputsCorrect(t, terraformOptions)
	checkFunc(t, terraformOptions)

	// Run `terraform init` and `terraform apply` again, with modified input.
	// We will see whether the cloud resources can be modified after their initial creation.
	terraformOptions.Vars["switchme"] = "false"
	terraform.InitAndApply(t, terraformOptions)
	CheckOutputsCorrect(t, terraformOptions)
	checkFunc(t, terraformOptions)

	return terraformOptions
}

// CheckOutputsCorrect verifies whether every terraform output named xxx_correct returned "true".
func CheckOutputsCorrect(t *testing.T, terraformOptions *terraform.Options) {
	reVerifiableOutput := regexp.MustCompile("correct$")
	want := "true"

	for output := range terraform.OutputAll(t, terraformOptions) {
		if !reVerifiableOutput.MatchString(output) {
			continue
		}

		// Run `terraform output` and get the named result.
		got := terraform.Output(t, terraformOptions, output)

		if got != want {
			t.Errorf("Mismatched result for terraform output %q:\ngot:  %q\nwant: %q\n", output, got, want)
		}
	}
}
