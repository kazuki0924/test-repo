locals {
  s3 = [
    for s3 in var.s3 : merge(s3, {
      name = "${var.common.prefix}${s3.resource_prefix}${s3.name_short}${var.common.suffix}"
      # var.s3[*].policiesがnullの場合でS3バケット名に"alb"または"nlb"が含まれる場合: var.policy_sets.elb
      # var.s3[*].policiesがnullの場合でS3バケット名に"tfstate"が含まれる場合: var.policy_sets.tfstate
      # var.s3[*].policiesがnullの場合: var.policy_sets.default
      policies = (
        s3.policies != null ?
        s3.policies :
        can(regex(".*(alb|nlb).*", s3.name_short)) ?
        var.policy_sets.elb :
        can(regex(".*(tfstate).*", s3.name_short)) ?
        var.policy_sets.tfstate :
        var.policy_sets.default
      )
    })
  ]
}

# [S3 (Simple Storage)]
# バケット
resource "aws_s3_bucket" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
  for_each = { for s3 in local.s3 : s3.name_short => s3 }

  bucket              = each.value.name
  force_destroy       = lookup(each.value.force_destroy, var.common.env, false)
  object_lock_enabled = false

  tags = {
    name       = each.value.name
    Name       = each.value.name
    name_short = each.value.name_short
  }

  lifecycle {
    ignore_changes = [
      tags["created_at"],
      tags["created_date"]
    ]
  }

  timeouts {
    create = each.value.timeouts[var.common.env].create
    update = each.value.timeouts[var.common.env].update
    delete = each.value.timeouts[var.common.env].delete
  }
}

# バケットのバージョニングの有効化
resource "aws_s3_bucket_versioning" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  bucket                = aws_s3_bucket.this[each.value.name_short].id
  expected_bucket_owner = local.common.aws_account_id

  versioning_configuration {
    status = "Enabled"
  }
}

# バケットの暗号化
# AWS Managed Keyでは出来なくてCustomer Managed Keyでは出来るKMSの細かい制御を必要とする要件が無い為、Risk Acceptedとする
# trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  bucket = aws_s3_bucket.this[each.value.name_short].id

  rule {
    apply_server_side_encryption_by_default {
      # default AWS managed key
      kms_master_key_id = null
      # ELB access logs supports SSE-S3 only
      # ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
      sse_algorithm = can(regex(".*(alb|nlb).*", each.value.name_short)) ? "AES256" : "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# パブリックアクセスのブロック
resource "aws_s3_bucket_public_access_block" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  bucket                  = aws_s3_bucket.this[each.value.name_short].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# バケットアクセスログの設定
resource "aws_s3_bucket_logging" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  bucket                = aws_s3_bucket.this[each.value.name_short].id
  expected_bucket_owner = local.common.aws_account_id
  target_bucket         = "${var.common.prefix}${each.value.access_log.bucket.resource_prefix}${each.value.access_log.bucket.name_short}${var.common.suffix}"
  target_prefix         = each.value.access_log.prefix

  # ref: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-targetobjectkeyformat.html
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = each.value.access_log.partition_date_source
    }
  }
}

# バケットのライフサイクル設定
resource "aws_s3_bucket_lifecycle_configuration" "log" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
  depends_on = [aws_s3_bucket.this, aws_s3_bucket_versioning.this]
  for_each = {
    for s3 in local.s3 : s3.name_short => s3
    # 用途がログの場合に有効化
    if contains(["log"], s3.usecase)
  }

  bucket = aws_s3_bucket.this[each.value.name_short].id

  rule {
    id     = "Expire"
    status = "Enabled"

    expiration {
      days = each.value.access_log.lifecycle.expiration.days
    }

    noncurrent_version_expiration {
      noncurrent_days = each.value.access_log.lifecycle.expiration.noncurrent_days
    }
  }

  rule {
    id     = "Delete"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = each.value.access_log.lifecycle.delete.days_after_initiation
    }
  }
}

# バケットのオーナーシップコントロール
resource "aws_s3_bucket_ownership_controls" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_policy.this,
    aws_s3_bucket_public_access_block.this
  ]
  for_each = {
    for s3 in local.s3 : s3.name_short => s3
  }

  bucket = aws_s3_bucket.this[each.value.name_short].id

  rule {
    object_ownership = each.value.ownership.object_ownership
  }
}

# [IAM (Identity & Access Management)]
data "aws_iam_policy_document" "deny_insecure_transport" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  statement {
    # TLS通信以外のアクセスを拒否
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this[each.value.name_short].arn,
      "${aws_s3_bucket.this[each.value.name_short].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "deny_outdated_tls" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  statement {
    # TLS1.2未満のアクセスを拒否
    sid     = "DenyOutdatedTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this[each.value.name_short].arn,
      "${aws_s3_bucket.this[each.value.name_short].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

data "aws_iam_policy_document" "deny_unencrypted_object_uploads" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  statement {
    # 暗号化されていないオブジェクトのアップロードを拒否
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "deny_incorrect_encryption_headers" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  statement {
    # KMS以外の暗号化方式を拒否
    sid       = "DenyIncorrectEncryptionHeaders"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
  }
}

data "aws_kms_key" "aws_managed_s3" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key
  key_id = "alias/aws/s3"
}

data "aws_iam_policy_document" "deny_incorrect_kms_key_sse" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this, data.aws_kms_key.aws_managed_s3]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  statement {
    # KMS KeyのARNはAWS Managed Key以外を拒否
    sid       = "DenyIncorrectKMSKeySSE"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [data.aws_kms_key.aws_managed_s3.arn]
    }
  }
}

# refs:
# - https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-ownership-migrating-acls-prerequisites.html#object-ownership-server-access-logs
# - https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
data "aws_iam_policy_document" "allow_logging_s3_amazonaws_com" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  # S3 Server Access Loggingの権限
  statement {
    # logging.s3.amazonaws.comにバケットへのログの書き込みを許可
    sid       = "AllowLoggingS3AmazonAWSComWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "ForAnyValue:ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.this[each.value.name_short].arn]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.common.aws_account_id]
    }
  }

  statement {
    # logging.s3.amazonaws.comにバケットACLの取得を許可
    sid       = "AllowLoggingS3AmazonAWSComRead"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[each.value.name_short].arn]

    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "allow_delivery_logs_amazonaws_com" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  # ログ転送の権限
  statement {
    # delivery.logs.amazonaws.comにログの書き込みを許可
    sid       = "AllowDeliveryLogsAmazonAWSComWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    # delivery.logs.amazonaws.comにバケットACL、バケット一覧の取得を許可
    sid       = "AllowDeliveryLogsAmazonAWSComRead"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.this[each.value.name_short].arn]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

# ref: https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/
locals {
  # List of AWS regions where permissions should be granted to the specified Elastic Load Balancing account ID
  # ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
  elb_service_accounts = {
    # AWS Configuration Standard allows: us-east-1, us-west-2, eu-west-1, ap-northeast-1
    us-east-1 = "127311923021"
    # us-east-2      = "033677994240"
    # us-west-1      = "027434742980"
    us-west-2 = "797873946194"
    # af-south-1     = "098369216593"
    # ap-east-1      = "754344448648"
    # ap-south-1     = "718504428378"
    ap-northeast-1 = "582318560864"
    # ap-northeast-2 = "600734575887"
    # ap-northeast-3 = "383597477331"
    # ap-southeast-1 = "114774131450"
    # ap-southeast-2 = "783225319266"
    # ap-southeast-3 = "589379963580"
    # ca-central-1   = "985666609251"
    # eu-central-1   = "054676820928"
    eu-west-1 = "156460612806"
    # eu-west-2      = "652711504416"
    # eu-west-3      = "009996457667"
    # eu-south-1     = "635631232127"
    # eu-north-1     = "897822967062"
    # me-south-1     = "076674570225"
    # sa-east-1      = "507241528517"
    # us-gov-west-1  = "048591011584"
    # us-gov-east-1  = "190560391635"
    # cn-north-1     = "638102146993"
    # cn-northwest-1 = "037604701340"
  }
}

data "aws_iam_policy_document" "allow_elb_service_account" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  depends_on = [aws_s3_bucket.this]
  for_each   = { for s3 in local.s3 : s3.name_short => s3 }

  # Policy for AWS Regions created before August 2022
  dynamic "statement" {
    for_each = local.elb_service_accounts

    content {
      sid       = "AllowELBServiceAccount${replace(title(statement.key), "-", "")}Write"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

      principals {
        identifiers = ["arn:aws:iam::${statement.value}:root"]
        type        = "AWS"
      }
    }
  }

  # Policy for AWS Regions created after August 2022 (e.g. Asia Pacific (Hyderabad), Asia Pacific (Melbourne), Europe (Spain), Europe (Zurich), Middle East (UAE))
  statement {
    sid       = "AllowLogDeliveryElasticLoadBalancingAmazonAWSComWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[each.value.name_short].arn}/*"]

    principals {
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid       = "AllowLogDeliveryElasticLoadBalancingAmazonAWSComRead"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.this[each.value.name_short].arn]

    principals {
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }
}

# [S3 (Simple Storage)]
# バケットポリシー
resource "aws_s3_bucket_policy" "this" {
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
  depends_on = [
    aws_s3_bucket.this,
    data.aws_iam_policy_document.deny_outdated_tls,
    data.aws_iam_policy_document.deny_insecure_transport,
    data.aws_iam_policy_document.deny_unencrypted_object_uploads,
    data.aws_iam_policy_document.deny_incorrect_encryption_headers,
    data.aws_iam_policy_document.deny_incorrect_kms_key_sse,
    data.aws_iam_policy_document.allow_logging_s3_amazonaws_com,
    data.aws_iam_policy_document.allow_delivery_logs_amazonaws_com,
    data.aws_iam_policy_document.allow_elb_service_account
  ]

  for_each = { for s3 in local.s3 : s3.name_short => s3 }

  bucket = aws_s3_bucket.this[each.value.name_short].id
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [for policy in flatten([
      contains(each.value.policies, "deny_outdated_tls") ? jsondecode(data.aws_iam_policy_document.deny_outdated_tls[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "deny_insecure_transport") ? jsondecode(data.aws_iam_policy_document.deny_insecure_transport[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "deny_unencrypted_object_uploads") ? jsondecode(data.aws_iam_policy_document.deny_unencrypted_object_uploads[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "deny_incorrect_encryption_headers") ? jsondecode(data.aws_iam_policy_document.deny_incorrect_encryption_headers[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "deny_incorrect_kms_key_sse") ? jsondecode(data.aws_iam_policy_document.deny_incorrect_kms_key_sse[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "allow_logging_s3_amazonaws_com") ? jsondecode(data.aws_iam_policy_document.allow_logging_s3_amazonaws_com[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "allow_delivery_logs_amazonaws_com") ? jsondecode(data.aws_iam_policy_document.allow_delivery_logs_amazonaws_com[each.value.name_short].json).Statement : null,
      contains(each.value.policies, "allow_elb_service_account") ? jsondecode(data.aws_iam_policy_document.allow_elb_service_account[each.value.name_short].json).Statement : null
    ]) : policy if policy != null]
  })
}
