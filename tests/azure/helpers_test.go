package azure_test

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
func uniqueID(t *testing.T) string {
	t.Helper()
	return fmt.Sprintf("%d", rand.Intn(9000)+1000) //nolint:gosec
}

// testLocation is the Azure region used for all integration tests.
const testLocation = "eastus"
