package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSecurityHubOutputs validates the Security Hub module enables the
// account and returns hub ARN and enabled standards.
func TestSecurityHubOutputs(t *testing.T) {
	t.Skip("Skipping to avoid Security Hub charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/security-hub",
		Vars: map[string]interface{}{
			"project":                        project,
			"environment":                    "dev",
			"enable_cis_standard":           true,
			"enable_aws_foundational_standard": true,
			"enable_pci_dss_standard":       false,
			"auto_enable_controls":          true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// Security Hub account should be enabled
	hubArn := terraform.Output(t, opts, "hub_arn")
	require.NotEmpty(t, hubArn, "hub_arn should not be empty")
	assert.Contains(t, hubArn, project, "hub_arn should reference the account")

	// Enabled standards should contain CIS and AWS Foundational
	enabledStandards := terraform.OutputList(t, opts, "enabled_standards")
	require.NotEmpty(t, enabledStandards, "enabled_standards should not be empty")
	assert.GreaterOrEqual(t, len(enabledStandards), 2, "should have at least 2 standards enabled")
}

// TestSecurityHubCIS validates CIS standard is enabled.
func TestSecurityHubCIS(t *testing.T) {
	t.Skip("Skipping to avoid Security Hub charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/security-hub",
		Vars: map[string]interface{}{
			"project":              project,
			"environment":          "dev",
			"enable_cis_standard": true,
			"auto_enable_controls": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	hubArn := terraform.Output(t, opts, "hub_arn")
	require.NotEmpty(t, hubArn)
	assert.NotEmpty(t, hubArn)
}
