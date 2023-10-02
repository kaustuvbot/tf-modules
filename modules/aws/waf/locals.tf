locals {
  managed_rule_groups = {
    common        = { name = "AWSManagedRulesCommonRuleSet", priority = 10 }
    bad_inputs    = { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 20 }
    sql_injection = { name = "AWSManagedRulesSQLiRuleSet", priority = 30 }
    ip_reputation = { name = "AWSManagedRulesAnonymousIPList", priority = 40 }
  }
}
