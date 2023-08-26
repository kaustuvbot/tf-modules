package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestKmsKeyOutputs validates the KMS module creates keys and returns
// non-empty ARN/ID/alias outputs for enabled keys.
func TestKmsKeyOutputs(t *testing.T) {
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/kms",
		Vars: map[string]interface{}{
			"project":                  project,
			"environment":              "dev",
			"enable_logs_key":          true,
			"enable_state_key":         false,
			"enable_general_key":       false,
			"deletion_window_in_days":  7,
			"enable_key_rotation":      true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// Logs key outputs should be populated
	logsKeyArn := terraform.Output(t, opts, "logs_key_arn")
	require.NotEmpty(t, logsKeyArn, "logs_key_arn should not be empty when enable_logs_key=true")
	assert.Contains(t, logsKeyArn, "arn:aws:kms")

	logsKeyAlias := terraform.Output(t, opts, "logs_key_alias")
	assert.Contains(t, logsKeyAlias, project, "logs key alias should include project name")

	// State key outputs should be null when disabled
	stateKeyArn := terraform.Output(t, opts, "state_key_arn")
	assert.Empty(t, stateKeyArn, "state_key_arn should be empty when enable_state_key=false")
}
