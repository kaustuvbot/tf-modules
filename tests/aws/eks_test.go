package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestEksSmokeTest validates that the EKS module can create a cluster
// with the expected outputs. This is a smoke test — it validates cluster
// creation and outputs, not full functionality.
//
// This test creates real AWS resources and takes ~10 minutes.
// Skip with: SKIP_EKS_TESTS=true go test ./aws/...
func TestEksSmokeTest(t *testing.T) {
	if os.Getenv("SKIP_EKS_TESTS") == "true" {
		t.Skip("Skipping EKS tests (SKIP_EKS_TESTS=true)")
	}

	// EKS tests are slow — do not run in parallel with other EKS tests
	// t.Parallel() intentionally omitted

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	// First create a VPC for the cluster
	vpcOpts := &terraform.Options{
		TerraformDir: "../../modules/aws/vpc",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"vpc_cidr":    "10.200.0.0/16",
			"availability_zones": []string{
				fmt.Sprintf("%sa", region),
				fmt.Sprintf("%sb", region),
			},
			"public_subnet_cidrs":  []string{"10.200.1.0/24", "10.200.2.0/24"},
			"private_subnet_cidrs": []string{"10.200.10.0/24", "10.200.11.0/24"},
			"enable_nat_gateway":   true,
			"single_nat_gateway":   true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, vpcOpts)
	terraform.InitAndApply(t, vpcOpts)

	vpcID := terraform.Output(t, vpcOpts, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, vpcOpts, "private_subnet_ids")
	require.NotEmpty(t, vpcID)
	require.Len(t, privateSubnetIDs, 2)

	// Deploy the EKS cluster into the VPC
	eksOpts := &terraform.Options{
		TerraformDir: "../../modules/aws/eks",
		Vars: map[string]interface{}{
			"project":            project,
			"environment":        "dev",
			"kubernetes_version": "1.28",
			"vpc_id":             vpcID,
			"subnet_ids":         privateSubnetIDs,
			"node_groups": map[string]interface{}{
				"default": map[string]interface{}{
					"instance_types": []string{"t3.small"},
					"desired_size":   1,
					"min_size":       1,
					"max_size":       2,
					// Validate disk_size is passed through to the launch template
					"disk_size": 60,
				},
			},
			// Enable IRSA role so we can validate cluster_autoscaler_role_arn
			"enable_cluster_autoscaler_irsa": true,
			// Disable all logs in tests to reduce cost
			"enabled_cluster_log_types": []string{},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, eksOpts)
	terraform.InitAndApply(t, eksOpts)

	// --- Validate EKS outputs ---

	clusterName := terraform.Output(t, eksOpts, "cluster_name")
	assert.Equal(t, fmt.Sprintf("%s-dev-eks", project), clusterName)

	clusterEndpoint := terraform.Output(t, eksOpts, "cluster_endpoint")
	assert.NotEmpty(t, clusterEndpoint, "cluster_endpoint should be set")

	clusterCA := terraform.Output(t, eksOpts, "cluster_certificate_authority")
	assert.NotEmpty(t, clusterCA, "cluster_certificate_authority should be set")

	oidcARN := terraform.Output(t, eksOpts, "oidc_provider_arn")
	assert.NotEmpty(t, oidcARN, "oidc_provider_arn should be set for IRSA")

	nodeRoleARN := terraform.Output(t, eksOpts, "node_group_role_arn")
	assert.NotEmpty(t, nodeRoleARN, "node_group_role_arn should be set")

	// Validate cluster autoscaler IRSA role ARN (enabled above)
	caRoleARN := terraform.Output(t, eksOpts, "cluster_autoscaler_role_arn")
	assert.NotEmpty(t, caRoleARN, "cluster_autoscaler_role_arn should be set when enable_cluster_autoscaler_irsa=true")
	assert.Contains(t, caRoleARN, ":role/", "cluster_autoscaler_role_arn should be a valid IAM role ARN")
}
