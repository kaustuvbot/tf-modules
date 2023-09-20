package azure_test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestKeyVaultSmokeTest deploys the Azure key-vault module and validates that
// vault_uri and key_vault_id outputs are correctly produced.
//
// Set SKIP_KEYVAULT_TESTS to skip this test.
func TestKeyVaultSmokeTest(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_KEYVAULT_TESTS") != "" {
		t.Skip("Skipping key vault integration test (SKIP_KEYVAULT_TESTS is set)")
	}

	location := testLocation
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		location = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	// Resource Group
	rgOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/resource-group",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"location":    location,
		},
		NoColor: true,
	}
	defer terraform.Destroy(t, rgOpts)
	terraform.InitAndApply(t, rgOpts)

	rgName := terraform.Output(t, rgOpts, "name")
	require.NotEmpty(t, rgName)

	tenantID := os.Getenv("ARM_TENANT_ID")
	require.NotEmpty(t, tenantID, "ARM_TENANT_ID environment variable must be set for key vault tests")

	// Key Vault
	kvOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/key-vault",
		Vars: map[string]interface{}{
			"project":                       project,
			"environment":                   "dev",
			"resource_group_name":           rgName,
			"location":                      location,
			"tenant_id":                     tenantID,
			"sku_name":                      "standard",
			"soft_delete_retention_days":    7,
			"purge_protection_enabled":      false, // allow destroy in tests
			"network_acls_default_action":   "Allow",
		},
		NoColor: true,
	}
	defer terraform.Destroy(t, kvOpts)
	terraform.InitAndApply(t, kvOpts)

	kvID := terraform.Output(t, kvOpts, "id")
	assert.NotEmpty(t, kvID, "id output must not be empty")

	kvName := terraform.Output(t, kvOpts, "name")
	assert.NotEmpty(t, kvName, "name output must not be empty")

	vaultURI := terraform.Output(t, kvOpts, "vault_uri")
	assert.NotEmpty(t, vaultURI, "vault_uri output must not be empty")
	assert.True(t, strings.HasPrefix(vaultURI, "https://"), "vault_uri must begin with https://")
}
