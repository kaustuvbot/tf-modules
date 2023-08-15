package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMonitoringSmokeTest validates the monitoring module creates an SNS topic
// and returns expected outputs without requiring a live EKS cluster.
func TestMonitoringSmokeTest(t *testing.T) {
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/monitoring",
		Vars: map[string]interface{}{
			"project":           project,
			"environment":       "dev",
			"enable_eks_alarms": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// SNS topic should always be created
	snsTopicArn := terraform.Output(t, opts, "sns_topic_arn")
	require.NotEmpty(t, snsTopicArn, "sns_topic_arn output should not be empty")

	snsTopicName := terraform.Output(t, opts, "sns_topic_name")
	assert.Contains(t, snsTopicName, project, "SNS topic name should include project name")

	// EKS alarm ARNs should be empty when enable_eks_alarms=false
	eksAlarmArns := terraform.OutputList(t, opts, "eks_alarm_arns")
	assert.Empty(t, eksAlarmArns, "eks_alarm_arns should be empty when enable_eks_alarms=false")
}
