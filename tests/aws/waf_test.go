package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestWafOutputs validates the WAF module creates a Web ACL with
// rate limiting and managed rules, returning valid ARN/ID outputs.
func TestWafOutputs(t *testing.T) {
	t.Skip("Skipping to avoid WAF charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/waf",
		Vars: map[string]interface{}{
			"project":                           project,
			"environment":                       "dev",
			"scope":                             "REGIONAL",
			"enable_rate_limiting":             true,
			"rate_limit_threshold":              2000,
			"enable_aws_managed_common_ruleset": true,
			"enable_aws_managed_bad_inputs":    true,
			"enable_aws_managed_sql_injection": false,
			"alb_arn_list":                      []string{},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// WAF Web ACL outputs should be populated
	webAclID := terraform.Output(t, opts, "web_acl_id")
	require.NotEmpty(t, webAclID, "web_acl_id should not be empty")
	assert.Contains(t, webAclID, project, "web_acl_id should include project name")

	webAclArn := terraform.Output(t, opts, "web_acl_arn")
	require.NotEmpty(t, webAclArn, "web_acl_arn should not be empty")
	assert.Contains(t, webAclArn, "arn:aws:waf", "web_acl_arn should be a valid ARN")

	webAclName := terraform.Output(t, opts, "web_acl_name")
	require.NotEmpty(t, webAclName, "web_acl_name should not be empty")
	assert.Contains(t, webAclName, "waf-", "web_acl_name should have waf- prefix")
}

// TestWafRegionalScope validates WAF scope is set to REGIONAL.
func TestWafRegionalScope(t *testing.T) {
	t.Skip("Skipping to avoid WAF charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/waf",
		Vars: map[string]interface{}{
			"project":           project,
			"environment":      "dev",
			"scope":            "REGIONAL",
			"enable_rate_limiting": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	webAclID := terraform.Output(t, opts, "web_acl_id")
	require.NotEmpty(t, webAclID)
	// Regional WAF IDs contain the region
	assert.Contains(t, webAclID, region)
}
