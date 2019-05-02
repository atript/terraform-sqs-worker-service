module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_basic" {
  statement {
    sid = "AllowWriteToCloudwatchLogs"

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "lambda_sqs" {
  source_json = "${data.aws_iam_policy_document.lambda_basic.json}"

  statement {
    sid       = "AllowSQSAttributes"
    effect    = "Allow"
    actions   = ["sqs:GetQueueAttributes"]
    resources = ["arn:aws:sqs:*:*:*"]
  }
}

data "aws_iam_policy_document" "lambda" {
  source_json = "${data.aws_iam_policy_document.lambda_sqs.json}"

  statement {
    sid       = "AllowFargateUpdates"
    effect    = "Allow"
    actions   = ["ecs:UpdateService", "ecs:ListTasks", "ecs:DescribeServices"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda" {
  name_prefix        = "${module.label.id}-lambda-trigger-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "lambda" {
  name_prefix = "${module.label.id}-lambda-policy-"
  role        = "${aws_iam_role.lambda.id}"

  policy = "${element(compact(concat(data.aws_iam_policy_document.lambda.*.json, data.aws_iam_policy_document.lambda_sqs.*.json, data.aws_iam_policy_document.lambda_basic.*.json)), 0)}"
}

data "local_file" "source_code" {
  filename = "${path.module}/index.js"
}

locals {
  source_code_hash = "${base64sha256(data.local_file.source_code.content)}"
}

resource "null_resource" "source_code" {
  triggers {
    source_code_hash = "${local.source_code_hash}"
  }
}

data "archive_file" "sqs_fargate_trigger" {
  type        = "zip"
  source_file = "${data.local_file.source_code.filename}"
  output_path = "${path.module}/.build/sqs_fargate_trigger.zip"
  depends_on  = ["null_resource.source_code"]
}
resource "aws_lambda_function" "sqs_fargate_trigger" {
  filename         = "${data.archive_file.sqs_fargate_trigger.output_path}"
  function_name    = "${module.label.id}-sqs-fargate-trigger"
  source_code_hash = "${data.archive_file.sqs_fargate_trigger.output_base64sha256}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "index.sqs_trigger"
  runtime          = "${var.runtime}"
  timeout          = "${var.lambda_timeout}"

  environment = {
    variables = {
      CONFIG    = "${jsonencode(var.trigger_config)}"
      timeout   = "${var.lambda_timeout}"
      frequency = "${var.trigger_check_frequency}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "sqs_lambda_trigger" {
  name                = "${module.label.id}-sqs-fargate-trigger"
  description         = "Fires lambda to check SQS queue and trigger ESC Fargate services"
  schedule_expression = "${var.schedule}"
}

resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
  rule      = "${aws_cloudwatch_event_rule.sqs_lambda_trigger.name}"
  target_id = "${module.label.id}-sqs-fargate-trigger"
  arn       = "${aws_lambda_function.sqs_fargate_trigger.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sqs_fargate_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sqs_fargate_trigger.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.sqs_lambda_trigger.arn}"
}
