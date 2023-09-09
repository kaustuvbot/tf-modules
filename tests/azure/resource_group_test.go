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

// TestResourceGroupOutputs validates the azure/resource-group module creates
// a resource group and returns non-empty name, location, and id outputs.
func TestResourceGroupOutputs(t *testing.T) {
	if os.Getenv("SKIP_RG_TESTS") != "" {
		t.Skip("Skipping Azure resource group tests (SKIP_RG_TESTS is set)")
	}
	t.Parallel()

	location := testLocation
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		location = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/azure/resource-group",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"location":    location,
			"tags": map[string]string{
				"ManagedBy": "terratest",
			},
		},
	}

	defer terraform.Destroy(t, opts)
	_, err := terraform.InitAndApplyE(t, opts)
	require.NoError(t, err, "terraform apply failed for azure/resource-group module")

	outName := terraform.Output(t, opts, "name")
	outLocation := terraform.Output(t, opts, "location")
	outID := terraform.Output(t, opts, "id")

	assert.NotEmpty(t, outName, "name output should not be empty")
	assert.Contains(t, outName, project, "resource group name should contain project")
	assert.NotEmpty(t, outLocation, "location output should not be empty")
	assert.NotEmpty(t, outID, "id output should not be empty")
	assert.True(t, strings.HasPrefix(outID, "/subscriptions/"),
		"id should start with /subscriptions/, got %s", outID)
	assert.Contains(t, outID, "resourceGroups",
		"id should contain 'resourceGroups', got %s", outID)
}
