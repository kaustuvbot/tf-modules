# AWS Stack — composed networking + compute

variable "project"            { type = string }
variable "environment"        { type = string }
variable "region"             { type = string }
variable "vpc_cidr"           { type = string }
variable "availability_zones" { type = list(string) }
variable "eks_version"        { type = string  default = "1.29" }
variable "enable_nat_gateway" { type = bool    default = true }
variable "tags"               { type = map(string) default = {} }

output "cluster_endpoint" { value = null } # populated once eks module wired
output "network_id"       { value = null } # populated once vpc module wired
