variable "project" {
  description = "Project name"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags for this environment"
  type        = map(string)
  default     = {}
}
