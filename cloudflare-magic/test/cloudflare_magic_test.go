package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCloudflareIntegrationBasic runs a full plan against the Cloudflare API.
// Requires CLOUDFLARE_API_TOKEN environment variable.
// Run with: go test -v -run TestCloudflareIntegration -timeout 30m
func TestCloudflareIntegrationBasic(t *testing.T) {
	t.Parallel()

	apiToken := os.Getenv("CLOUDFLARE_API_TOKEN")
	domain := os.Getenv("CLOUDFLARE_TEST_DOMAIN")

	if apiToken == "" || domain == "" {
		t.Skip("Skipping integration test: CLOUDFLARE_API_TOKEN and CLOUDFLARE_TEST_DOMAIN must be set")
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"cloudflare_api_token": apiToken,
		},
		NoColor: true,
	})

	// Only plan, don't apply (avoids creating real resources in CI)
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	assert.Contains(t, planOutput, "cloudflare_dns_record.domain")
	assert.Contains(t, planOutput, "cloudflare_dns_record.public")
}

// TestCloudflareIntegrationSingleTunnel runs a full plan for the single-tunnel example.
// Requires CLOUDFLARE_API_TOKEN environment variable.
func TestCloudflareIntegrationSingleTunnel(t *testing.T) {
	t.Parallel()

	apiToken := os.Getenv("CLOUDFLARE_API_TOKEN")
	domain := os.Getenv("CLOUDFLARE_TEST_DOMAIN")

	if apiToken == "" || domain == "" {
		t.Skip("Skipping integration test: CLOUDFLARE_API_TOKEN and CLOUDFLARE_TEST_DOMAIN must be set")
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/single-tunnel",
		Vars: map[string]interface{}{
			"cloudflare_api_token": apiToken,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	assert.Contains(t, planOutput, "cloudflare_zero_trust_tunnel_cloudflared.tunnel")
	assert.Contains(t, planOutput, "cloudflare_dns_record.tunnel")
	assert.Contains(t, planOutput, "cloudflare_zero_trust_access_application.protected")
	assert.Contains(t, planOutput, "cloudflare_zero_trust_access_policy.protected")
}

// TestProviderVersion ensures the module requires the v5 provider
func TestProviderVersion(t *testing.T) {
	t.Parallel()

	content, err := os.ReadFile("../main.tf")
	require.NoError(t, err)

	assert.Contains(t, string(content), `version = "~> 5.0"`, "Module should require Cloudflare provider v5")
	assert.NotContains(t, string(content), "cloudflare_record", "Module should not use deprecated cloudflare_record resource")
	assert.Contains(t, string(content), "cloudflare_dns_record", "Module should use cloudflare_dns_record resource")
}

// TestV5ResourceNames checks that all resources use v5-compatible names
func TestV5ResourceNames(t *testing.T) {
	t.Parallel()

	content, err := os.ReadFile("../main.tf")
	require.NoError(t, err)

	mainTf := string(content)

	// Verify v5 data source syntax
	assert.Contains(t, mainTf, "filter = {", "data.cloudflare_zone should use filter block in v5")
	assert.NotContains(t, mainTf, "allow_overwrite", "allow_overwrite was removed in v5")

	// Verify v5 tunnel resource syntax
	assert.Contains(t, mainTf, "tunnel_secret", "Tunnel should use tunnel_secret (not secret) in v5")

	// Verify v5 tunnel config syntax
	assert.Contains(t, mainTf, "config = {", "Tunnel config should use attribute syntax in v5")

	// Verify v5 policy syntax (standalone, no application_id)
	assert.NotContains(t, mainTf, "application_id", "Policies should not reference application_id in v5")
}
