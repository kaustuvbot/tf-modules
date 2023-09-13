# Azure Stack — composed networking + compute + monitoring

variable "project"                { type = string }
variable "environment"            { type = string }
variable "location"               { type = string }
variable "vnet_cidr"              { type = string }
variable "kubernetes_version"     { type = string  default = "1.29" }
variable "enable_private_cluster" { type = bool    default = false }
variable "tags"                   { type = map(string) default = {} }

output "cluster_endpoint" { value = null } # populated once aks module wired
output "network_id"       { value = null } # populated once vnet module wired
