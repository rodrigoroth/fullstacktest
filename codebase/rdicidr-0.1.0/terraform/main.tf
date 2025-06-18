locals {
  env        = terraform.workspace
  app_bucket = "${var.project_name}-${local.env}-static"
  log_bucket = "${var.project_name}-${local.env}-logs"
}

# S3 bucket for static website
resource "aws_s3_bucket" "static_site" {
  bucket = local.app_bucket

  tags = {
    Name        = local.app_bucket
    Environment = local.env
  }
}

resource "aws_s3_bucket_public_access_block" "static_site_block" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = local.log_bucket

  tags = {
    Name        = local.log_bucket
    Environment = local.env
  }
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Policy to allow CloudFront to write logs
data "aws_iam_policy_document" "log_bucket_policy" {
  statement {
    sid     = "AllowCloudFrontLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.log_bucket_policy.json
}

# CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.project_name} (${local.env})"
}

# Policy to allow OAI to read from S3
data "aws_iam_policy_document" "static_site_oai_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.static_site_oai_policy.json
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = var.cloudfront_enabled
  comment             = "CDN for ${var.project_name} (${local.env})"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "${var.project_name}-${local.env}-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project_name}-${local.env}-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "CF-${var.project_name}-${local.env}"
    Environment = local.env
  }
}
