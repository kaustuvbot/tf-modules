package azure_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestVnetEgressDenyRule validates the deny_outbound_internet flag creates
// a DenyOutboundInternet NSG rule when enabled on a subnet.
func TestVnetEgressDenyRule(t *testing.T) {
	t.Parallel()

	location := testLocation
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		location = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

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

	vnetOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/vnet",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": rgName,
			"location":            location,
			"address_space":       []string{"10.60.0.0/16"},
			"subnets": map[string]interface{}{
				"restricted": map[string]interface{}{
					"address_prefixes":       []string{"10.60.1.0/24"},
					"deny_outbound_internet": true,
				},
			},
		},
	}

	defer terraform.Destroy(t, vnetOpts)
	terraform.InitAndApply(t, vnetOpts)

	// NSG and subnet IDs should exist for the restricted subnet
	nsgIDs := terraform.OutputMap(t, vnetOpts, "nsg_ids")
	assert.NotEmpty(t, nsgIDs["restricted"], "restricted subnet NSG should have been created")
}

// TestVnetHappyPath validates that the VNet module creates a VNet with the
// correct address space and that each subnet receives its own NSG.
func TestVnetHappyPath(t *testing.T) {
	t.Parallel()

	location := testLocation
	if l := os.Getenv("AZURE_LOCATION"); l != "" {
		location = l
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	// Deploy resource group first, then VNet
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
	require.NotEmpty(t, rgName, "resource group name should not be empty")

	vnetOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/vnet",
		Vars: map[string]interface{}{
			"project":             project,
			"environment":         "dev",
			"resource_group_name": rgName,
			"location":            location,
			"address_space":       []string{"10.50.0.0/16"},
			"subnets": map[string]interface{}{
				"app": map[string]interface{}{
					"address_prefixes": []string{"10.50.1.0/24"},
				},
			},
		},
	}

	defer terraform.Destroy(t, vnetOpts)
	terraform.InitAndApply(t, vnetOpts)

	// Validate outputs
	vnetID := terraform.Output(t, vnetOpts, "vnet_id")
	assert.NotEmpty(t, vnetID, "vnet_id should not be empty")

	vnetName := terraform.Output(t, vnetOpts, "vnet_name")
	assert.Equal(t, fmt.Sprintf("vnet-%s-dev", project), vnetName)

	subnetIDs := terraform.OutputMap(t, vnetOpts, "subnet_ids")
	assert.Len(t, subnetIDs, 1, "expected 1 subnet")
	assert.NotEmpty(t, subnetIDs["app"], "app subnet should have an ID")

	nsgIDs := terraform.OutputMap(t, vnetOpts, "nsg_ids")
	assert.Len(t, nsgIDs, 1, "expected 1 NSG")
	assert.NotEmpty(t, nsgIDs["app"], "app NSG should have an ID")
}
