package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestVpcHappyPath validates the VPC module creates the expected
// resources with correct attributes.
func TestVpcHappyPath(t *testing.T) {
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/vpc",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"vpc_cidr":    "10.100.0.0/16",
			"availability_zones": []string{
				fmt.Sprintf("%sa", region),
				fmt.Sprintf("%sb", region),
			},
			"public_subnet_cidrs":  []string{"10.100.1.0/24", "10.100.2.0/24"},
			"private_subnet_cidrs": []string{"10.100.10.0/24", "10.100.11.0/24"},
			"enable_nat_gateway":   false,
			"single_nat_gateway":   true,
			"tags": map[string]string{
				"TestRun": uid,
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// --- Validate outputs ---

	vpcID := terraform.Output(t, opts, "vpc_id")
	require.NotEmpty(t, vpcID, "vpc_id output should not be empty")

	vpcCIDR := terraform.Output(t, opts, "vpc_cidr")
	assert.Equal(t, "10.100.0.0/16", vpcCIDR)

	// Validate public subnets
	publicSubnetIDs := terraform.OutputList(t, opts, "public_subnet_ids")
	assert.Len(t, publicSubnetIDs, 2, "expected 2 public subnets")

	// Validate private subnets
	privateSubnetIDs := terraform.OutputList(t, opts, "private_subnet_ids")
	assert.Len(t, privateSubnetIDs, 2, "expected 2 private subnets")

	// Validate subnets are in the correct VPC
	for _, subnetID := range append(publicSubnetIDs, privateSubnetIDs...) {
		subnet := aws.GetSubnetById(t, subnetID, region)
		assert.Equal(t, vpcID, subnet.VpcId, "subnet should belong to the created VPC")
	}

	// Validate IGW exists
	igwID := terraform.Output(t, opts, "internet_gateway_id")
	assert.NotEmpty(t, igwID, "internet_gateway_id should be set when public subnets exist")

	// Validate no NAT gateway created (enable_nat_gateway = false)
	natGatewayIDs := terraform.OutputList(t, opts, "nat_gateway_ids")
	assert.Empty(t, natGatewayIDs, "nat_gateway_ids should be empty when enable_nat_gateway=false")

	// Validate required tags on VPC
	vpcTags := aws.GetTagsForVpc(t, vpcID, region)
	assert.Equal(t, project, vpcTags["Project"])
	assert.Equal(t, "dev", vpcTags["Environment"])
	assert.Equal(t, "terraform", vpcTags["ManagedBy"])
}
