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

// TestPrivateDnsSmokeTest validates that the azure/private-dns module creates
// a private DNS zone and VNet links with the expected outputs.
//
// Requires ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET.
// Skip with: SKIP_PRIVATE_DNS_TESTS=true go test ./azure/...
func TestPrivateDnsSmokeTest(t *testing.T) {
	if os.Getenv("SKIP_PRIVATE_DNS_TESTS") == "true" {
		t.Skip("Skipping private DNS tests (SKIP_PRIVATE_DNS_TESTS=true)")
	}

	tenantID := os.Getenv("ARM_TENANT_ID")
	require.NotEmpty(t, tenantID, "ARM_TENANT_ID must be set")

	t.Parallel()

	uid := uniqueID(t)

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

	// Create a VNet to link to the DNS zone
	vnetOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/vnet",
		Vars: map[string]interface{}{
			"project":             fmt.Sprintf("test-%s", uid),
			"environment":         "dev",
			"resource_group_name": rgName,
			"location":            testLocation,
			"address_space":       []string{"10.100.0.0/16"},
			"subnets":             map[string]interface{}{},
		},
	}

	defer terraform.Destroy(t, vnetOpts)
	terraform.InitAndApply(t, vnetOpts)

	vnetID := terraform.Output(t, vnetOpts, "vnet_id")
	require.NotEmpty(t, vnetID)

	// Deploy private DNS zone with a VNet link
	dnsOpts := &terraform.Options{
		TerraformDir: "../../modules/azure/private-dns",
		Vars: map[string]interface{}{
			"project":             fmt.Sprintf("test-%s", uid),
			"environment":         "dev",
			"resource_group_name": rgName,
			"zone_name":           fmt.Sprintf("test%s.internal", uid),
			"vnet_links": map[string]interface{}{
				"main-vnet": vnetID,
			},
		},
	}

	defer terraform.Destroy(t, dnsOpts)
	terraform.InitAndApply(t, dnsOpts)

	// --- Validate outputs ---

	zoneID := terraform.Output(t, dnsOpts, "zone_id")
	assert.NotEmpty(t, zoneID, "zone_id should not be empty")
	assert.Contains(t, zoneID, "/privateDnsZones/", "zone_id should be a valid Azure Private DNS Zone resource ID")

	zoneName := terraform.Output(t, dnsOpts, "zone_name")
	assert.True(t,
		strings.HasSuffix(zoneName, ".internal"),
		"zone_name should end with .internal, got: %s", zoneName,
	)

	vnetLinkIDs := terraform.OutputMap(t, dnsOpts, "vnet_link_ids")
	assert.Len(t, vnetLinkIDs, 1, "expected 1 vnet_link_id")

	linkID, ok := vnetLinkIDs["main-vnet"]
	assert.True(t, ok, "vnet_link_ids should contain 'main-vnet' key")
	assert.Contains(t, linkID, "/virtualNetworkLinks/", "link ID should be a valid Azure VNet link resource ID")
}
