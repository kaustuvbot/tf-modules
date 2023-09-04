package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestIamOidcProviderOutputs validates the IAM module creates the GitHub OIDC
// provider and CI roles, returning expected ARN outputs.
func TestIamOidcProviderOutputs(t *testing.T) {
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/iam",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"github_org":  "test-org",
			"github_repositories": []string{
				fmt.Sprintf("test-org/test-repo-%s", uid),
			},
			"apply_branch": "main",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// OIDC provider should exist
	oidcArn := terraform.Output(t, opts, "oidc_provider_arn")
	require.NotEmpty(t, oidcArn, "oidc_provider_arn should not be empty")
	assert.Contains(t, oidcArn, "arn:aws:iam")

	oidcUrl := terraform.Output(t, opts, "oidc_provider_url")
	assert.Contains(t, oidcUrl, "token.actions.githubusercontent.com")

	// Plan and apply roles should exist
	planRoleArn := terraform.Output(t, opts, "plan_role_arn")
	assert.Contains(t, planRoleArn, project, "plan role ARN should include project name")

	applyRoleArn := terraform.Output(t, opts, "apply_role_arn")
	assert.Contains(t, applyRoleArn, project, "apply role ARN should include project name")
	assert.NotEqual(t, planRoleArn, applyRoleArn, "plan and apply roles should be distinct")
}
