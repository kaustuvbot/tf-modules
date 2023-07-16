package aws_test

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

// testRegion is the AWS region used for all integration tests.
const testRegion = "us-east-1"
