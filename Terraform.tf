provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "dev-laiba-wania-bucket-8"
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
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
      "Resource": "arn:aws:s3:::dev-laiba-wania-bucket-8/*",
      "Condition": {
        "StringNotEquals": {
          "aws:Referer": "https://${aws_cloudfront_distribution.my_distribution.domain_name}/*"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "https://github.com/Laiba1010/web-project.git/index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "css" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "css/"
  source = "https://github.com/Laiba1010/web-project.git/css/"
}

resource "aws_s3_bucket_object" "fonts" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "fonts/"
  source = "https://github.com/Laiba1010/web-project.git/fonts/"
}

resource "aws_s3_bucket_object" "images" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "images/"
  source = "https://github.com/Laiba1010/web-project.git/images/"
}

resource "aws_s3_bucket_object" "js" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "js/"
  source = "https://github.com/Laiba1010/web-project.git/js/"
}

resource "aws_s3_bucket_object" "not_found" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "404.html"
  source = "https://github.com/Laiba1010/web-project.git/404.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "about" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "about.html"
  source = "https://github.com/Laiba1010/web-project.git/about.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "contact" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "contact.html"
  source = "https://github.com/Laiba1010/web-project.git/contact.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "food" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "food.html"
  source = "https://github.com/Laiba1010/web-project.git/food.html"
  content_type = "text/html"
}
resource "aws_cloudfront_distribution" "my_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront Distribution"

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

 origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my_bucket.id
  
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "My CloudFront OAI"
}

resource "aws_s3_bucket_policy" "bucket_policy_oai" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.my_oai.iam_arn
        }
        Action = "s3:GetObject"
        Resource = join("", [aws_s3_bucket.my_bucket.arn, "/*"])
      }
    ]
  })
}
