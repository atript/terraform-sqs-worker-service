locals {
  log_group    = "${var.namespace}-${var.stage}-workers"
  cluster_name = "${var.namespace}-${var.stage}-workers"
}

module "service_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "aws_ecs_cluster" "service_cluster" {
  count = "${var.workers_cluster_arn == "" ? 1 : 0}"
  name  = "${local.cluster_name}"
}

resource "aws_cloudwatch_log_group" "worker_group" {
  count = "${var.worker_log_group == "" ? 1 : 0}"
  name  = "${local.log_group}"
}

module "container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.6.0"
  container_name  = "${module.service_label.id}-container"
  container_image = "${var.container_image}"

  log_options = {
    awslogs-region        = "${var.region}"
    awslogs-group         = "${var.worker_log_group == "" ? local.log_group : var.worker_log_group}"
    awslogs-stream-prefix = "${var.name}"
  }

  environment = "${var.environment}"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${module.service_label.id}"
  container_definitions    = "${module.container_definition.json}"
  task_role_arn            = "${aws_iam_role.worker.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "${aws_iam_role.worker.arn}"
}

resource "aws_ecs_service" "worker_service" {
  name            = "${module.service_label.id}-service"
  cluster         = "${var.workers_cluster_arn == "" ? aws_ecs_cluster.service_cluster.arn : var.workers_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "0"

  launch_type = "FARGATE"

  network_configuration {
    security_groups  = ["${var.security_group_ids}"]
    subnets          = ["${var.subnet_ids}"]
    assign_public_ip = true
  }
}

module "lambda" {
  source                  = "./sqsFargateTrigger"
  namespace               = "${var.namespace}"
  name                    = "${var.name}"
  stage                   = "${var.stage}"
  delimiter               = "${var.delimiter}"
  attributes              = "${var.attributes}"
  tags                    = "${var.tags}"
  trigger_check_frequency = "${var.trigger_check_frequency}"
  lambda_timeout          = "${var.lambda_timeout}"

  trigger_config = [{
    cluster  = "${var.workers_cluster_arn == "" ? aws_ecs_cluster.service_cluster.arn : var.workers_cluster_arn}"
    service  = "${aws_ecs_service.worker_service.name}"
    QueueUrl = "${var.sqs_queue}"
  }]
}
