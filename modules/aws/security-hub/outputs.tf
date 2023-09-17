output "hub_arn" {
  description = "ARN of the Security Hub account enablement"
  value       = aws_securityhub_account.this.id
}

output "enabled_standards" {
  description = "List of enabled standard ARNs"
  value = compact([
    var.enable_cis_standard ? try(aws_securityhub_standards_subscription.cis[0].id, "") : "",
    var.enable_aws_foundational_standard ? try(aws_securityhub_standards_subscription.aws_foundational[0].id, "") : "",
    var.enable_pci_dss_standard ? try(aws_securityhub_standards_subscription.pci_dss[0].id, "") : "",
  ])
}
