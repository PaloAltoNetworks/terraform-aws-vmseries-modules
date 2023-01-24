package helpers

import (
	"crypto/tls"
	"net"
	"net/http"
	"testing"
	"time"
)

func CheckHttpGetWebApp(t *testing.T, outputValue string) bool {
	// Do not verify insecure connection
	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	// Define how many retries and how often to do in order to check if application is healthy
	sleepBetweenRetry := 15 * time.Second
	numberOfRetries := 60
	urlHealthy := false

	// Check in the loop if application is healthy
	for i := 1; i <= numberOfRetries && !urlHealthy; i++ {
		// HTTP GET
		time.Sleep(sleepBetweenRetry)

		//TODO: Check if client can replace :22
		//client := http.Client{
		//	Timeout: 15 * time.Second,
		//}
		resp, err := http.Get(outputValue)

		// Display errors, if there were any, or HTTPS status code, if no errors
		if err != nil {
			t.Logf("Waiting for application (%d/%d)... error HTTP GET: %v\n", i, numberOfRetries, err)
		} else {
			t.Logf("Application HTTP GET status code: %v", resp.StatusCode)
			urlHealthy = resp.StatusCode == 200
		}
	}
	return urlHealthy
}

func CheckTcpPortOpened(t *testing.T, outputValue string) bool {
	// verify if port is opened (defined with address in outputValue)
	_, err := net.DialTimeout("tcp", outputValue, 5*time.Second)
	return err == nil
}
