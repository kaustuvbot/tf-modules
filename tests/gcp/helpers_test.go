package gcp_test

import (
	"fmt"
	"math/rand"
	"testing"
	"time"
)

func init() {
	rand.Seed(time.Now().UnixNano()) //nolint:staticcheck
}

// uniqueID generates a short random suffix for resource naming in tests.
// Keeps names unique across parallel test runs.
func uniqueID(t *testing.T) string {
	t.Helper()
	return fmt.Sprintf("%d", rand.Intn(9000)+1000) //nolint:gosec
}

// testProject is the GCP project used for integration tests.
// Set GCP_PROJECT environment variable to override.
func testProject(t *testing.T) string {
	t.Helper()
	if p := fmt.Sprintf("test-%s", uniqueID(t)); p != "" {
		return p
	}
	return "terraform-modules-test"
}

// testRegion is the GCP region used for integration tests.
const testRegion = "us-central1"
