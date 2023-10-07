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

// TestContainerRegistrySmokeTest validates that the azure/container-registry
// module creates an ACR with the expected login_server and outputs.
//
// Requires ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET.
// Skip with: SKIP_ACR_TESTS=true go test ./azure/...
func TestContainerRegistrySmokeTest(t *testing.T) {
	if os.Getenv("SKIP_ACR_TESTS") == "true" {
		t.Skip("Skipping ACR tests (SKIP_ACR_TESTS=true)")
	}

	tenantID := os.Getenv("ARM_TENANT_ID")
	require.NotEmpty(t, tenantID, "ARM_TENANT_ID must be set")

	t.Parallel()

	uid := uniqueID(t)
	// ACR names: alphanumeric only, so strip hyphens. Max 50 chars.
	project := fmt.Sprintf("test%s", uid)

	// Create a resource group for the test
	rgOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/resource-group",
		Vars: map[string]interface{}{
			"project":     fmt.Sprintf("test-%s", uid),
			"environment": "dev",
			"location":    testLocation,
		},
	}

	defer terraform.Destroy(t, rgOpts)
	terraform.InitAndApply(t, rgOpts)

	rgName := terraform.Output(t, rgOpts, "resource_group_name")
	require.NotEmpty(t, rgName)

	// Deploy the container registry
	acrOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/container-registry",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": rgName,
			"location":            testLocation,
			"sku":                 "Basic", // cheapest SKU for tests
		},
	}

	defer terraform.Destroy(t, acrOpts)
	terraform.InitAndApply(t, acrOpts)

	// --- Validate outputs ---

	registryID := terraform.Output(t, acrOpts, "registry_id")
	assert.NotEmpty(t, registryID, "registry_id should not be empty")
	assert.Contains(t, registryID, "/Microsoft.ContainerRegistry/registries/", "registry_id should be a valid Azure resource ID")

	loginServer := terraform.Output(t, acrOpts, "login_server")
	assert.NotEmpty(t, loginServer, "login_server should not be empty")
	assert.True(t,
		strings.HasSuffix(loginServer, ".azurecr.io"),
		"login_server should end with .azurecr.io, got: %s", loginServer,
	)

	registryName := terraform.Output(t, acrOpts, "registry_name")
	assert.NotEmpty(t, registryName, "registry_name should not be empty")
	// ACR name should be alphanumeric (hyphens stripped by the module)
	assert.Regexp(t, `^[a-zA-Z0-9]+$`, registryName, "registry_name should be alphanumeric")
}
