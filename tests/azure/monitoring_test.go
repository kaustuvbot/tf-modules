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

// TestAzureMonitoringAlertOutputs validates the azure/monitoring module creates
// metric alert rules and returns non-empty cpu_alert_id and memory_alert_id.
//
// Requires an existing AKS cluster ID passed via AZURE_AKS_CLUSTER_ID.
// Skip with: SKIP_AZURE_MONITORING_TESTS=true go test ./azure/...
func TestAzureMonitoringAlertOutputs(t *testing.T) {
	if os.Getenv("SKIP_AZURE_MONITORING_TESTS") != "" {
		t.Skip("Skipping Azure monitoring tests (SKIP_AZURE_MONITORING_TESTS is set)")
	}

	aksClusterID := os.Getenv("AZURE_AKS_CLUSTER_ID")
	if aksClusterID == "" {
		t.Skip("Skipping: AZURE_AKS_CLUSTER_ID not set (requires an existing AKS cluster resource ID)")
	}

	t.Parallel()

	location := testLocation
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		location = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test%s", uid)

	// Create a resource group for the alert rules
	rgOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/resource-group",
		Vars: map[string]interface{}{
			"project":     fmt.Sprintf("test-%s", uid),
			"environment": "dev",
			"location":    location,
		},
	}

	defer terraform.Destroy(t, rgOpts)
	_, err := terraform.InitAndApplyE(t, rgOpts)
	require.NoError(t, err, "terraform apply failed for resource-group module")

	rgName := terraform.Output(t, rgOpts, "name")
	require.NotEmpty(t, rgName, "resource group name should not be empty")

	// Deploy monitoring alerts
	monOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/monitoring",
		Vars: map[string]interface{}{
			"project":                  project,
			"environment":              "dev",
			"resource_group_name":      rgName,
			"location":                 location,
			"aks_cluster_id":           aksClusterID,
			"cpu_threshold_percent":    85,
			"memory_threshold_percent": 85,
		},
	}

	defer terraform.Destroy(t, monOpts)
	_, err = terraform.InitAndApplyE(t, monOpts)
	require.NoError(t, err, "terraform apply failed for azure/monitoring module")

	cpuAlertID := terraform.Output(t, monOpts, "cpu_alert_id")
	memAlertID := terraform.Output(t, monOpts, "memory_alert_id")

	assert.NotEmpty(t, cpuAlertID, "cpu_alert_id should not be empty")
	assert.NotEmpty(t, memAlertID, "memory_alert_id should not be empty")
	assert.True(t, strings.Contains(cpuAlertID, "/metricalerts/"),
		"cpu_alert_id should contain /metricalerts/, got %s", cpuAlertID)
	assert.True(t, strings.Contains(memAlertID, "/metricalerts/"),
		"memory_alert_id should contain /metricalerts/, got %s", memAlertID)
}
