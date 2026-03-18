package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestBasicExampleValidation validates the basic example passes terraform validate
func TestBasicExampleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		NoColor:      true,
	})

	output := terraform.InitAndValidate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestSingleTunnelExampleValidation validates the single-tunnel example
func TestSingleTunnelExampleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/single-tunnel",
		NoColor:      true,
	})

	output := terraform.InitAndValidate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestMultipleTunnelsExampleValidation validates the multiple-tunnels example
func TestMultipleTunnelsExampleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/multiple-tunnels",
		NoColor:      true,
	})

	output := terraform.InitAndValidate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestMixedExampleValidation validates the mixed (public + zero trust) example
func TestMixedExampleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/mixed",
		NoColor:      true,
	})

	output := terraform.InitAndValidate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}
