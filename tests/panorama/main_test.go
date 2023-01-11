package bootstrap

import (
	"crypto/tls"
	"net/http"
	"testing"
	"time"

	"github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tests/internal/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestOutputForModulePanoramaWithFullVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_full.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_panorama_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// // check Panorama URL
		{
			OutputName: "panorama_url",
			Operation:  "NotEmpty",
		},
		{
			Operation: "CheckFunction",
			Check:     CheckHttpGetWebUiLoginPage,
			Message:   "After bootstrapping, which takes few minutes, web UI for Panorama should be accessible",
		},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}

func CheckHttpGetWebUiLoginPage(t *testing.T, terraformOptions *terraform.Options) bool {
	// Do not verify insecure connection
	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	// Define how many retries and how often to do in order to check if Panorama web UI is healthy
	sleepBetweenRetry := 15 * time.Second
	numberOfRetries := 60
	panoramaHealthy := false
	panoramaUrl := terraform.Output(t, terraformOptions, "panorama_url")

	// Check in the loop if Panorama web UI is healthy
	for i := 1; i <= numberOfRetries && !panoramaHealthy; i++ {
		// HTTP GET for login page
		time.Sleep(sleepBetweenRetry)
		resp, err := http.Get(panoramaUrl + "/php/login.php")

		// Display errors, if there were any, or HTTPS status code, if no errors
		if err != nil {
			t.Logf("Waiting for Panorama (%d/%d)... error HTTP GET: %v\n", i, numberOfRetries, err)
		} else {
			t.Logf("Panorama Web UI HTTP GET status code: %v", resp.StatusCode)
			panoramaHealthy = resp.StatusCode == 200
		}
	}
	return panoramaHealthy
}

func TestOutputForModulePanoramaWithMinimumVariables(t *testing.T) {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform_minimum.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix": "terratest_module_panorama_",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})

	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{
		// // check Panorama URL
		{
			OutputName: "panorama_url",
			Operation:  "NotEmpty",
		},
	}

	// deploy test infrastructure and verify outputs
	testskeleton.DeployInfraCheckOutputs(t, terraformOptions, assertList)
}
