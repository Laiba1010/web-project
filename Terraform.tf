provider "aws" {
  region = "eu-west-1"
}

# Declare the input variable
variable "object_cache_control" {
  description = "Cache control configuration for S3 objects"
  type        = map(object({
    content_type = string
    cache_control = string
  }))
  default     = {}
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "dev-laiba-wania-bucket-1"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::dev-laiba-wania-bucket-1/*",
      "Condition": {
        "StringNotEquals": {
          "aws:Referer": "https://${aws_cloudfront_distribution.static_website_distribution.domain_name}/*"
        }
      }
    }
  ]
}
POLICY
}

# Configure automated backups using S3 lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_configuration" {
 bucket = aws_s3_bucket.my_bucket.bucket

  rule {
    id      = "BackupRule"
    status  = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

# Implement cache-control headers on S3 objects
resource "aws_s3_bucket_object" "cache_control" {
  for_each = var.object_cache_control

  bucket = aws_s3_bucket.my_bucket.bucket
  key          = each.key
  content_type = each.value.content_type

  metadata = {
    "Cache-Control" = each.value.cache_control
  }
}

# Create CloudFront distribution
resource "aws_cloudfront_distribution" "static_website_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website distribution"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

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

   origin {
    domain_name = aws_s3_bucket.my_bucket.website_domain
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port             = 80
      https_port            = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols  = ["TLSv1.2"]
      origin_path           = "/index.html"  # Specify the index.html file as the origin
    }
  }

  tags = {
    Name = "StaticWebsiteDistribution"
  }
}
