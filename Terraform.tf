provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "dev-laiba-wania-bucket-1"
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
      "Resource": "arn:aws:s3:::dev-laiba-wania-bucket-1/*",
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
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.my_oai.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = join("", [aws_s3_bucket.my_bucket.arn, "/*"])
      }
    ]
  })
}

data "github_repository_file" "files" {
  repository = "Laiba1010/web-project"
  file       = "css/*"
}

data "github_repository_file" "fonts" {
  repository = "Laiba1010/web-project"
  file       = "fonts/*"
}

data "github_repository_file" "images" {
  repository = "Laiba1010/web-project"
  file       = "images/*"
}

data "github_repository_file" "js" {
  repository = "Laiba1010/web-project"
  file       = "js/*"
}

data "github_repository_file" "error" {
  repository = "Laiba1010/web-project"
  file       = "404.html"
}

data "github_repository_file" "about" {
  repository = "Laiba1010/web-project"
  file       = "about.html"
}

data "github_repository_file" "contact" {
  repository = "Laiba1010/web-project"
  file       = "contact.html"
}

data "github_repository_file" "food" {
  repository = "Laiba1010/web-project"
  file       = "food.html"
}

data "github_repository_file" "index" {
  repository = "Laiba1010/web-project"
  file       = "index.html"
}


resource "aws_s3_bucket_object" "deployed_files" {
  for_each = data.github_repository_file.files

  bucket = aws_s3_bucket.my_bucket.id
  key    = each.value.path
  source = each.value.download_url
  etag   = each.value.sha
}
