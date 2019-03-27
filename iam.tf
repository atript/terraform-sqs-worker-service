data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "write_logs" {
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

data "aws_iam_policy_document" "read_write_s3_logs" {
  statement {
    sid = "AllowWriteToCloudwatchLogs"

    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = ["arn:aws:s3:*:*:*"]
  }
}

data "aws_iam_policy_document" "allow_sqs" {
  source_json = "${data.aws_iam_policy_document.write_logs.json}"

  statement {
    sid    = "AllowSQS"
    effect = "Allow"

    actions = [
      "sqs:*",
    ]

    resources = ["arn:aws:sqs:*:*:*"]
  }
}

data "aws_iam_policy_document" "allow_ecr" {
  source_json = "${data.aws_iam_policy_document.allow_sqs.json}"

  statement {
    sid    = "AllowECR"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "worker" {
  name_prefix        = "${module.service_label.id}-worker-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy" "worker_policy" {
  name_prefix = "${module.service_label.id}-worker-policy-"
  role        = "${aws_iam_role.worker.id}"

  policy = "${element(compact(concat( data.aws_iam_policy_document.allow_ecr.*.json)), 0)}"
}
