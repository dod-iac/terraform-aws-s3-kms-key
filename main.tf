/**
 * ## Usage
 *
 * Creates a KMS Key for use with S3.
 *
 * ```hcl
 * module "s3_kms_key" {
 *   source = "dod-iac/s3-kms-key/aws"
 *
 *   name = format("alias/app-%s-s3-%s", var.application, var.environment)
 *   description = format("A KMS key used to encrypt objects at rest in S3 for %s:%s.", var.application, var.environment)
 *   principals = [var.instance_role_arn]
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 * ## Terraform Version
 *
 * Terraform 0.12. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.
 *
 * Terraform 0.11 is not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}
data "aws_region" "current" {}

# https://docs.aws.amazon.com/kms/latest/developerguide/services-s3.html#s3-customer-cmk-policy

data "aws_iam_policy_document" "s3" {

  policy_id = "key-policy-s3"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    #checkov:skip=CKV_AWS_109:Root is root
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.partition,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    #checkov:skip=CKV_AWS_111:Resource policy
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = range(length(var.principals) > 0 ? 1 : 0)
    content {
      sid = "AllowFull"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.principals
      }
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.*.amazonaws.com"]
      }
      #checkov:skip=CKV_AWS_111:Resource policy
      resources = ["*"]
    }
  }



  dynamic "statement" {
    for_each = var.principals_extended
    content {
      sid = format("AllowFull-%s-%s", statement.value["type"], join("-", statement.value["identifiers"]))
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      effect = "Allow"
      principals {
        type        = statement.value["type"]
        identifiers = statement.value["identifiers"]
      }
      
      #checkov:skip=CKV_AWS_111:Resource policy
      resources = ["*"]
    }

  }

}

resource "aws_kms_key" "s3" {
  description             = var.description
  deletion_window_in_days = var.key_deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.s3.json
  tags                    = var.tags
}

resource "aws_kms_alias" "s3" {
  name          = var.name
  target_key_id = aws_kms_key.s3.key_id
}
