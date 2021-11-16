package vpc_plan

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestMain(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: ".",
	})

	// Schedule `terraform destroy` at the end of the test, to clean up the created resources.
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform plan` and fail the test if there are any errors.
	// This specific test is not intended to execute `terraform apply` at all.
	terraform.InitAndPlan(t, terraformOptions)
}
