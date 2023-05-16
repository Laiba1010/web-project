provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "dev-laiba-wania-bucket-1"
  acl    = "private"
}

resource "aws_s3_bucket_object" "cache_control" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "index.html"

  cache_control = "max-age=3600"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront Distribution"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.my_bucket.website_endpoint
    origin_id   = aws_s3_bucket.my_bucket.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.my_bucket.id
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
}

