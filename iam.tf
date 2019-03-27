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

data "aws_iam_policy_document" "read_write_s3_and_logs" {
  statement {
    sid = "AllowWriteToCloudwatchLogs"

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutAnalyticsConfiguration",
      "s3:GetObjectVersionTagging",
      "s3:CreateBucket",
      "s3:ReplicateObject",
      "s3:GetObjectAcl",
      "s3:DeleteBucketWebsite",
      "s3:PutLifecycleConfiguration",
      "s3:GetObjectVersionAcl",
      "s3:PutObjectTagging",
      "s3:HeadBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketWebsite",
      "s3:PutReplicationConfiguration",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketNotification",
      "s3:PutBucketCORS",
      "s3:GetReplicationConfiguration",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutBucketNotification",
      "s3:PutBucketLogging",
      "s3:GetAnalyticsConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucketByTags",
      "s3:GetInventoryConfiguration",
      "s3:GetBucketTagging",
      "s3:PutAccelerateConfiguration",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLogging",
      "s3:ListBucketVersions",
      "s3:ReplicateTags",
      "s3:RestoreObject",
      "s3:ListBucket",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetObjectVersionTorrent",
      "s3:AbortMultipartUpload",
      "s3:PutBucketTagging",
      "s3:GetBucketRequestPayment",
      "s3:GetObjectTagging",
      "s3:GetMetricsConfiguration",
      "s3:DeleteBucket",
      "s3:PutBucketVersioning",
      "s3:GetBucketPublicAccessBlock",
      "s3:ListBucketMultipartUploads",
      "s3:PutMetricsConfiguration",
      "s3:PutObjectVersionTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:PutInventoryConfiguration",
      "s3:GetObjectTorrent",
      "s3:GetAccountPublicAccessBlock",
      "s3:PutBucketWebsite",
      "s3:ListAllMyBuckets",
      "s3:PutBucketRequestPayment",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:ReplicateDelete",
      "s3:GetObjectVersion",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_sqs" {
  source_json = "${data.aws_iam_policy_document.read_write_s3_and_logs.json}"

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
