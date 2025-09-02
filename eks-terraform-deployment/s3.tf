# s3.tf

resource "aws_s3_bucket" "logs" {
  bucket = "${var.cluster_name}-logs-${data.aws_caller_identity.current.account_id}"

  tags = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = 30 # Configure retention period
    }
  }
}
