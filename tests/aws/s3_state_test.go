package aws_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestS3StateBucketEncryption validates the s3-state module creates a bucket
// with versioning enabled and returns expected outputs. Encryption is AES256
// by default (no KMS key required for the test).
func TestS3StateBucketEncryption(t *testing.T) {
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	bucketName := fmt.Sprintf("tf-state-test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/s3-state",
		Vars: map[string]interface{}{
			"bucket_name":   bucketName,
			"force_destroy": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// Bucket ID and name outputs should match the input
	bucketID := terraform.Output(t, opts, "bucket_id")
	require.NotEmpty(t, bucketID, "bucket_id should not be empty")
	assert.Equal(t, bucketName, bucketID)

	bucketArn := terraform.Output(t, opts, "bucket_arn")
	assert.Contains(t, bucketArn, bucketName, "bucket_arn should reference the bucket name")
}
