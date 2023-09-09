package aws_test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestBudgetsSmokeTest deploys the budgets module and validates that budget
// names and anomaly monitor ARN outputs are correctly produced.
func TestBudgetsSmokeTest(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_BUDGET_TESTS") != "" {
		t.Skip("Skipping budgets integration test (SKIP_BUDGET_TESTS is set)")
	}

	uid := uniqueID(t)
	project := "tftest-" + uid
	environment := "dev"

	tfOpts := &terraform.Options{
		TerraformDir: "../../modules/aws/budgets",
		Vars: map[string]interface{}{
			"project":               project,
			"environment":           environment,
			"monthly_budget_amount": 50,
			"currency":              "USD",
			"enable_anomaly_detection": true,
			"anomaly_threshold_amount": 10,
			"tags": map[string]string{
				"ManagedBy": "terratest",
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, tfOpts)
	terraform.InitAndApply(t, tfOpts)

	monthlyBudgetName := terraform.Output(t, tfOpts, "monthly_budget_name")
	assert.NotEmpty(t, monthlyBudgetName, "monthly_budget_name output must not be empty")

	forecastBudgetName := terraform.Output(t, tfOpts, "forecast_budget_name")
	assert.NotEmpty(t, forecastBudgetName, "forecast_budget_name output must not be empty")

	anomalyMonitorARN := terraform.Output(t, tfOpts, "anomaly_monitor_arn")
	assert.NotEmpty(t, anomalyMonitorARN, "anomaly_monitor_arn output must not be empty when anomaly detection is enabled")
}
