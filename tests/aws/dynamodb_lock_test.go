package aws_test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestDynamoDBLockOutputs validates the dynamodb-lock module creates a table
// and returns non-empty table_name and table_arn outputs.
func TestDynamoDBLockOutputs(t *testing.T) {
	if os.Getenv("SKIP_DYNAMODB_TESTS") != "" {
		t.Skip("Skipping DynamoDB lock tests (SKIP_DYNAMODB_TESTS is set)")
	}
	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	tableName := fmt.Sprintf("tf-lock-test-%s", uid)

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/dynamodb-lock",
		Vars: map[string]interface{}{
			"table_name":               tableName,
			"enable_ttl":               true,
			"ttl_attribute":            "ExpiresAt",
			"enable_delete_protection": false,
			"table_class":              "STANDARD",
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	_, err := terraform.InitAndApplyE(t, opts)
	require.NoError(t, err, "terraform apply failed for dynamodb-lock module")

	outName := terraform.Output(t, opts, "table_name")
	outARN := terraform.Output(t, opts, "table_arn")

	assert.NotEmpty(t, outName, "table_name output should not be empty")
	assert.Equal(t, tableName, outName, "table_name should match the input variable")
	assert.NotEmpty(t, outARN, "table_arn output should not be empty")
	assert.True(t, strings.HasPrefix(outARN, "arn:aws:dynamodb:"),
		"table_arn should start with arn:aws:dynamodb:, got %s", outARN)
	assert.Contains(t, outARN, tableName, "table_arn should contain the table name")
}
