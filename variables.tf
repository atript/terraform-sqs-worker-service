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

variable "container_image" {
  description = "the container image to run"
}

variable "subnet_ids" {
  type        = "list"
  description = "subnet ids"
}

variable "security_group_ids" {
  type        = "list"
  description = "security_group_ids ids"
}

variable "environment" {
  type        = "list"
  description = "environment variables"
}

variable "cpu" {
  default     = "256"
  description = "cpu of worker"
}

variable "memory" {
  default     = "1024"
  description = "memory of worker"
}

variable "worker_log_group" {
  default     = ""
  description = "worker_log_group name"
}

variable "workers_cluster_arn" {
  default     = ""
  description = "cluster arn"
}

variable "sqs_queue" {
  description = "sqs queue for tasks"
}

variable "region" {
  description = "region"
}

variable "trigger_check_frequency" {
  description = "trigger_check_frequency"
  default     = 10
}

variable "lambda_timeout" {
  description = "lambda_timeout"
  default     = 900
}


variable "scaling_strategy" {
  description = "Scaling strategy for lambda trigger"
  default     = "DEFAULT_STRATEGY"
}

variable "max_tasks_count" {
  description = "Max number of tasks for current worker"
  default     = 1
}
