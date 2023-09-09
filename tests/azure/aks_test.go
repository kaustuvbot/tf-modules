package azure_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAksSmokeTest validates that the AKS module provisions a cluster with the
// expected name convention and exposes the required outputs.
//
// Set SKIP_AKS_TESTS=true to skip this test (AKS clusters take ~10 minutes).
func TestAksSmokeTest(t *testing.T) {
	if os.Getenv("SKIP_AKS_TESTS") == "true" {
		t.Skip("Skipping AKS tests (SKIP_AKS_TESTS=true)")
	}

	t.Parallel()

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
	}
	defer terraform.Destroy(t, rgOpts)
	terraform.InitAndApply(t, rgOpts)

	rgName := terraform.Output(t, rgOpts, "name")
	require.NotEmpty(t, rgName)

	// VNet
	vnetOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/vnet",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": rgName,
			"location":            location,
			"address_space":       []string{"10.60.0.0/16"},
			"subnets": map[string]interface{}{
				"aks-system": map[string]interface{}{
					"address_prefixes": []string{"10.60.1.0/24"},
				},
			},
		},
	}
	defer terraform.Destroy(t, vnetOpts)
	terraform.InitAndApply(t, vnetOpts)

	subnetIDs := terraform.OutputMap(t, vnetOpts, "subnet_ids")
	systemSubnetID := subnetIDs["aks-system"]
	require.NotEmpty(t, systemSubnetID)

	// AKS
	aksOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/aks",
		Vars: map[string]interface{}{
			"project":                       project,
			"environment":                   "dev",
			"resource_group_name":           rgName,
			"location":                      location,
			"system_node_pool_subnet_id":    systemSubnetID,
			"system_node_pool_vm_size":      "Standard_D2s_v3",
			"system_node_pool_node_count":   1,
			"system_node_pool_min_count":    1,
			"system_node_pool_max_count":    2,
		},
	}
	defer terraform.Destroy(t, aksOpts)
	terraform.InitAndApply(t, aksOpts)

	clusterName := terraform.Output(t, aksOpts, "cluster_name")
	assert.Equal(t, fmt.Sprintf("aks-%s-dev", project), clusterName)

	clusterID := terraform.Output(t, aksOpts, "cluster_id")
	assert.NotEmpty(t, clusterID)

	oidcURL := terraform.Output(t, aksOpts, "oidc_issuer_url")
	assert.Empty(t, oidcURL, "oidc_issuer_url should be empty when workload_identity_enabled=false")

	// Validate kubelet identity is always provisioned (required for ACR pull assignments)
	kubeletObjectID := terraform.Output(t, aksOpts, "kubelet_identity_object_id")
	assert.NotEmpty(t, kubeletObjectID, "kubelet_identity_object_id must be set for ACR pull role assignments")

	// Validate user_node_pool_ids is an empty map when no user pools are configured
	nodePoolIDs := terraform.OutputMap(t, aksOpts, "user_node_pool_ids")
	assert.Empty(t, nodePoolIDs, "user_node_pool_ids should be an empty map when user_node_pools is not configured")
}
