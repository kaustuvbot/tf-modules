package aws_test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestLoggingSmokeTest deploys the logging module and validates that the
// central log group and log bucket outputs are correctly produced.
// CloudTrail and GuardDuty are disabled to minimise test cost and duration.
//
// Set SKIP_LOGGING_TESTS to skip (e.g. when running in CI without S3 perms).
func TestLoggingSmokeTest(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_LOGGING_TESTS") != "" {
		t.Skip("Skipping logging integration test (SKIP_LOGGING_TESTS is set)")
	}

	uid := uniqueID(t)
	project := "tftest-" + uid

	tfOpts := &terraform.Options{
		TerraformDir: "../../modules/aws/logging",
		Vars: map[string]interface{}{
			"project":           project,
			"environment":       "dev",
			"retention_in_days": 7,
			"enable_cloudtrail": false,
			"enable_config":     false,
			"enable_guardduty":  false,
			"tags": map[string]string{
				"ManagedBy": "terratest",
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, tfOpts)
	terraform.InitAndApply(t, tfOpts)

	logGroupName := terraform.Output(t, tfOpts, "log_group_name")
	assert.NotEmpty(t, logGroupName, "log_group_name output must not be empty")

	logGroupARN := terraform.Output(t, tfOpts, "log_group_arn")
	assert.NotEmpty(t, logGroupARN, "log_group_arn output must not be empty")

	logBucketID := terraform.Output(t, tfOpts, "log_bucket_id")
	assert.NotEmpty(t, logBucketID, "log_bucket_id output must not be empty")

	// CloudTrail is disabled so cloudtrail_arn should be empty
	cloudtrailARN := terraform.Output(t, tfOpts, "cloudtrail_arn")
	assert.Empty(t, cloudtrailARN, "cloudtrail_arn should be empty when enable_cloudtrail=false")
}
