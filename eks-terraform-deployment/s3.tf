# =====================================================================
# S3 Bucket for Logs and Data Storage
# =====================================================================

resource "aws_s3_bucket" "logs" {
  bucket = "${var.cluster_name}-logs-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enhanced S3 Bucket lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "logs_enhanced" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle-management"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Transition to Infrequent Access after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier Flexible Retrieval after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Glacier Deep Archive after 180 days
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete objects after 365 days
    expiration {
      days = 365
    }

    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Separate rule for old versions
  rule {
    id     = "version-lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# S3 Bucket notification for log analysis (optional)
resource "aws_s3_bucket_notification" "logs_notification" {
  count  = var.enable_fluentbit ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  # You can add CloudWatch Events or Lambda triggers here if needed
  # For example, to trigger log analysis when new files are uploaded
}
