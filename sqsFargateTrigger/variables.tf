variable "namespace" {
  type        = "string"
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = "string"
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "name" {
  default     = "app"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "schedule" {
  description = "The rate of lamda triggering"
  default     = "rate(1 minute)"
}

variable "runtime" {
  description = "The function runtime to use. (nodejs, nodejs4.3, nodejs6.10, nodejs8.10, java8, python2.7, python3.6, dotnetcore1.0, dotnetcore2.0, dotnetcore2.1, nodejs4.3-edge, go1.x)"
  default     = "nodejs8.10"
}

variable "package_hash" {
  default     = ""
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename."
}

variable "trigger_config" {
  type        = "list"
  default     = []
  description = "Used to configure sqs and workers to scale with lambda trigger"
}

variable "trigger_check_frequency" {
  default     = 10
  description = "once per seconds"
}

variable "lambda_timeout" {
  default     = 60
  description = "ttl of lambda"
}
