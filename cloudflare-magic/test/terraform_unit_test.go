package test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// setupModuleCopy creates a temp copy of the module directory for isolated testing
func setupModuleCopy(t *testing.T, varsContent string) string {
	t.Helper()
	moduleDir, err := files.CopyTerraformFolderToTemp("../", t.Name())
	require.NoError(t, err)

	if varsContent != "" {
		err = os.WriteFile(filepath.Join(moduleDir, "test.auto.tfvars"), []byte(varsContent), 0644)
		require.NoError(t, err)
	}

	return moduleDir
}

// TestModuleRootValidation validates the root module initializes correctly
func TestModuleRootValidation(t *testing.T) {
	t.Parallel()

	dir := setupModuleCopy(t, `
cloudflare_api_token = "test-token"
domain = {
  name    = "example.com"
  target  = "203.0.113.1"
  proxied = true
}
default_tunnel_name = "test-tunnel"
`)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: dir,
		NoColor:      true,
	})

	terraform.Init(t, terraformOptions)
	output := terraform.Validate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestModuleWithPublicRecordsOnly validates configuration with only public records
func TestModuleWithPublicRecordsOnly(t *testing.T) {
	t.Parallel()

	dir := setupModuleCopy(t, `
cloudflare_api_token = "test-token"
domain = {
  name    = "example.com"
  target  = "203.0.113.1"
  proxied = true
}
default_tunnel_name = "test-tunnel"
dns_records = [
  {
    name    = "www"
    type    = "CNAME"
    content = "example.com"
    proxied = true
  }
]
`)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: dir,
		NoColor:      true,
	})

	terraform.Init(t, terraformOptions)
	output := terraform.Validate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}

// TestModuleWithZeroTrustRecords validates configuration with zero trust records
func TestModuleWithZeroTrustRecords(t *testing.T) {
	t.Parallel()

	dir := setupModuleCopy(t, `
cloudflare_api_token   = "test-token"
default_allowed_emails = ["admin@example.com"]
domain = {
  name    = "example.com"
  target  = "203.0.113.1"
  proxied = true
}
default_tunnel_name = "test-tunnel"
dns_records = [
  {
    name = "app"
    zero_trust = {
      protected = true
      tunnel = {
        name           = "test-tunnel"
        local_protocol = "http"
        local_port     = "3000"
      }
    }
  }
]
`)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: dir,
		NoColor:      true,
	})

	terraform.Init(t, terraformOptions)
	output := terraform.Validate(t, terraformOptions)
	assert.Contains(t, output, "Success")
}
