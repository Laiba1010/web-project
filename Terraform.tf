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
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::dev-laiba-wania-bucket-1/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_lambda_function" "edge_function" {
  filename      = "myLambdaFunction.js"
  function_name = "my-edge-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-edge-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_permission" "edge_permission" {
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.edge_function.function_name
  principal     = "edgelambda.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.my_distribution.arn
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

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.edge_function.qualified_arn
      include_body = false
    }
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
