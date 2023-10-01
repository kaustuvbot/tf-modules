package azure_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFrontDoorOutputs validates the azure/front-door module creates a profile,
// endpoint, origin group, and returns valid outputs.
func TestFrontDoorOutputs(t *testing.T) {
	if os.Getenv("SKIP_AZURE_TESTS") != "" {
		t.Skip("Skipping Azure tests (SKIP_AZURE_TESTS is set)")
	}
	t.Skip("Skipping to avoid Front Door charges — enable manually")

	_ = testLocation // satisfy unused check
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		_ = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/azure/front-door",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": "test-rg",
			"sku_name":           "Standard_AzureFrontDoor",
			"origins": map[string]interface{}{
				"primary": map[string]interface{}{
					"host_name": "example.azurewebsites.net",
					"priority":  1,
					"weight":    100,
				},
			},
			"routes": map[string]interface{}{
				"default": map[string]interface{}{
					"patterns_to_match":   []string{"/*"},
					"supported_protocols": []string{"Http", "Https"},
				},
			},
		},
	}

	defer terraform.Destroy(t, opts)
	_, err := terraform.InitAndApplyE(t, opts)
	require.NoError(t, err, "terraform apply failed for azure/front-door module")

	// Profile outputs should be populated
	profileID := terraform.Output(t, opts, "profile_id")
	require.NotEmpty(t, profileID, "profile_id should not be empty")
	assert.Contains(t, profileID, "frontdoorprofiles", "profile_id should be a valid resource ID")

	profileName := terraform.Output(t, opts, "profile_name")
	require.NotEmpty(t, profileName, "profile_name should not be empty")
	assert.Contains(t, profileName, project, "profile_name should contain project name")

	// Endpoint outputs
	endpointHostname := terraform.Output(t, opts, "endpoint_hostname")
	require.NotEmpty(t, endpointHostname, "endpoint_hostname should not be empty")
	assert.Contains(t, endpointHostname, "azurefd.net", "endpoint_hostname should be a Front Door endpoint")

	endpointID := terraform.Output(t, opts, "endpoint_id")
	require.NotEmpty(t, endpointID, "endpoint_id should not be empty")

	// Origin group output
	originGroupID := terraform.Output(t, opts, "origin_group_id")
	require.NotEmpty(t, originGroupID, "origin_group_id should not be empty")
	assert.Contains(t, originGroupID, "originGroups", "origin_group_id should be a valid resource ID")
}

// TestFrontDoorMinimal validates minimal configuration works.
func TestFrontDoorMinimal(t *testing.T) {
	if os.Getenv("SKIP_AZURE_TESTS") != "" {
		t.Skip("Skipping Azure tests (SKIP_AZURE_TESTS is set)")
	}
	t.Skip("Skipping to avoid Front Door charges — enable manually")

	_ = testLocation // satisfy unused check
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		_ = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/azure/front-door",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": "test-rg",
		},
	}

	defer terraform.Destroy(t, opts)
	_, err := terraform.InitAndApplyE(t, opts)
	require.NoError(t, err, "terraform apply should succeed with minimal config")

	profileID := terraform.Output(t, opts, "profile_id")
	require.NotEmpty(t, profileID)
	assert.NotEmpty(t, profileID)
}
