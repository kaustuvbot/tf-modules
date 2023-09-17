variable "project" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}
