provider "aws" {
  region = "eu-west-1"
}

# Set up the S3 bucket for static website hosting
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "dev-laiba-wania-bucket-1"
  acl    = "public-read"  # Allow public read access

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }
}

# Configure bucket policy to allow public access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.static_website_bucket.bucket}/*"
    }
  ]
}
EOF
}

# Configure CloudFront distribution
resource "aws_cloudfront_distribution" "static_website_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Static website distribution"
  price_class     = "PriceClass_100"

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

  origins {
    domain_name = aws_s3_bucket.static_website_bucket.bucket
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port             = 80
      https_port            = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols  = ["TLSv1.2"]
    }
  }

  # Lambda function association
  lambda_function_association {
    event_type   = "viewer-request"
    lambda_arn   = "arn:aws:lambda:<ap-southeast-1>:${var.AWS_ACCOUNT_ID}:function:<myFunction1>:<Versions (1)>"
    include_body = false
  }

  tags = {
    Name = "StaticWebsiteDistribution"
  }
}

# Deploy changes using CloudFront invalidation
resource "aws_cloudfront_distribution" "static_website_distribution_invalidation" {
  depends_on = [aws_cloudfront_distribution.static_website_distribution]

  # Specify the paths to invalidate
  for_each = aws_s3_bucket_object.cache_control

  distribution_id = aws_cloudfront_distribution.static_website_distribution.id

  invalidation_batch {
    caller_reference = timestamp()
    paths            = [each.key]
  }
}


