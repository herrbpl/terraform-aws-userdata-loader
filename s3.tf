data "aws_caller_identity" "current" {}

locals {
  default_logging_bucket = "${var.name}-bucket-log"
}

resource "aws_s3_bucket" "bucket_log" {
  count  = "${var.logging_bucket == "" ? 1 : 0}"
  bucket = "${local.default_logging_bucket}"
  acl    = "log-delivery-write"

  tags = {
    name = "LoggingBucket"
  }

  force_destroy = true

  lifecycle {
        prevent_destroy = false
        ignore_changes = ["bucket"]
    }

}

data "aws_s3_bucket" "scripts" {
  count = "${var.bucket == "" ? 0 : 1}"
  bucket = "${var.bucket}"
}



resource "aws_s3_bucket" "scripts" {  
  count = "${var.bucket == "" ? 1 : 0}"
  bucket_prefix        = "${var.name}-"
  force_destroy = true
  tags          = "${map("Name", format("%s", var.name))}"

  logging {
    target_bucket = "${var.logging_bucket != "" ? var.logging_bucket : aws_s3_bucket.bucket_log[0].id}"
    target_prefix = "log/"
  }

   versioning {
    enabled = true
  }
}

locals {
  bucket_id = "${var.bucket == "" ? aws_s3_bucket.scripts[0].id : data.aws_s3_bucket.scripts[0].id}"
  bucket_arn = "${var.bucket == "" ? aws_s3_bucket.scripts[0].arn : data.aws_s3_bucket.scripts[0].arn}"
}

resource "aws_iam_user" "boot_user" {
    name = "${local.bucket_id}-user"
}

resource "aws_iam_access_key" "boot_user" {
    user = "${aws_iam_user.boot_user.name}"
}

resource "aws_s3_bucket_policy" "grant" {
  bucket = "${local.bucket_id}"  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": ["${local.bucket_arn}",
                   "${local.bucket_arn}/*"],
      "Principal": {
          "AWS": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_access_key.boot_user.user}"]        
      }
    }
  ]
}
EOF
}

resource "aws_iam_user_policy" "grant" {
    name = "test"
    user = "${aws_iam_user.boot_user.name}"
    policy= <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "${local.bucket_arn}",
                "${local.bucket_arn}/*"
            ]
        }
   ]
}
EOF
}

