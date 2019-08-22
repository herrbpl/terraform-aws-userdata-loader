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

resource "aws_s3_bucket" "scripts" {  
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

resource "aws_iam_user" "boot_user" {
    name = "${aws_s3_bucket.scripts.bucket}-user"
}

resource "aws_iam_access_key" "boot_user" {
    user = "${aws_iam_user.boot_user.name}"
}

resource "aws_s3_bucket_policy" "grant" {
  bucket = "${aws_s3_bucket.scripts.id}"  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": ["${aws_s3_bucket.scripts.arn}",
                   "${aws_s3_bucket.scripts.arn}/*"],
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
                "${aws_s3_bucket.scripts.arn}",
                "${aws_s3_bucket.scripts.arn}/*"
            ]
        }
   ]
}
EOF
}

