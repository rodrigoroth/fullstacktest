output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
  description = "Public URL of the Cloudfront Distribution"
}

output "static_site_bucket" {
  value = aws_s3_bucket.static_site.bucket
  description = "Name of the S3 bucket that stores the static website files"
}

output "log_bucket" {
  value = aws_s3_bucket.log_bucket.bucket
  description = "Name of the S3 bucket that stores the CloudFront access logs"
}
