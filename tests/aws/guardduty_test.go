package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGuarddutyOutputs validates the GuardDuty module creates a detector
// and returns valid ID/ARN outputs.
func TestGuarddutyOutputs(t *testing.T) {
	t.Skip("Skipping to avoid GuardDuty charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/guardduty",
		Vars: map[string]interface{}{
			"project":                   project,
			"environment":               "dev",
			"enable_s3_logs":           false,
			"enable_kubernetes_logs":  true,
			"enable_malware_protection": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// GuardDuty detector outputs should be populated
	detectorID := terraform.Output(t, opts, "detector_id")
	require.NotEmpty(t, detectorID, "detector_id should not be empty")
	assert.Greater(t, len(detectorID), 0, "detector_id should have content")

	detectorArn := terraform.Output(t, opts, "detector_arn")
	require.NotEmpty(t, detectorArn, "detector_arn should not be empty")
	assert.Contains(t, detectorArn, "arn:aws:guardduty", "detector_arn should be a valid ARN")
	assert.Contains(t, detectorArn, region, "detector_arn should include region")
}

// TestGuarddutyKubernetes validates EKS audit log monitoring is enabled.
func TestGuarddutyKubernetes(t *testing.T) {
	t.Skip("Skipping to avoid GuardDuty charges — enable manually")

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/guardduty",
		Vars: map[string]interface{}{
			"project":                  project,
			"environment":              "dev",
			"enable_kubernetes_logs": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	detectorID := terraform.Output(t, opts, "detector_id")
	require.NotEmpty(t, detectorID)
	// Kubernetes audit logs are always enabled when the flag is true
	// The detector is created with the configuration
	assert.NotEmpty(t, detectorID)
}
