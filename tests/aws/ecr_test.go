package aws_test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestEcrSmokeTest validates that the ECR module creates repositories with
// the expected URL format and ARN outputs.
//
// This test creates real AWS resources (ECR repositories are free but take
// a few seconds to provision).
// Skip with: SKIP_ECR_TESTS=true go test ./aws/...
func TestEcrSmokeTest(t *testing.T) {
	if os.Getenv("SKIP_ECR_TESTS") == "true" {
		t.Skip("Skipping ECR tests (SKIP_ECR_TESTS=true)")
	}

	t.Parallel()

	region := testRegion
	if r := os.Getenv("AWS_REGION"); r != "" {
		region = r
	}

	uid := uniqueID(t)
	project := fmt.Sprintf("test%s", uid) // ECR path component — no hyphens needed

	opts := &terraform.Options{
		TerraformDir: "../../modules/aws/ecr",
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "dev",
			"repositories": map[string]interface{}{
				"app": map[string]interface{}{
					"scan_on_push": false, // avoid scan charges in tests
				},
				"worker": map[string]interface{}{
					"image_tag_mutability": "IMMUTABLE",
					"scan_on_push":         false,
				},
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// --- Validate outputs ---

	repoURLs := terraform.OutputMap(t, opts, "repository_urls")
	assert.Len(t, repoURLs, 2, "expected 2 repository_urls entries")

	for name, url := range repoURLs {
		assert.NotEmpty(t, url, "repository_url for %s should not be empty", name)
		assert.Contains(t, url, ".dkr.ecr.", "repository_url should contain .dkr.ecr.")
		assert.Contains(t, url, ".amazonaws.com/", "repository_url should contain .amazonaws.com/")
		assert.True(t,
			strings.HasSuffix(url, fmt.Sprintf("/%s/dev/%s", project, name)),
			"repository_url %s should end with /<project>/dev/<name>", url,
		)
	}

	repoARNs := terraform.OutputMap(t, opts, "repository_arns")
	assert.Len(t, repoARNs, 2, "expected 2 repository_arns entries")

	for name, arn := range repoARNs {
		assert.Contains(t, arn, ":ecr:", "ARN for %s should contain :ecr:", name)
		assert.Contains(t, arn, ":repository/", "ARN for %s should contain :repository/", name)
	}

	registryID := terraform.Output(t, opts, "registry_id")
	assert.NotEmpty(t, registryID, "registry_id should not be empty")
	assert.Len(t, registryID, 12, "registry_id (AWS account ID) should be 12 digits")
}
