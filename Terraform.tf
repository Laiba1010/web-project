provider "aws" {
  region = "eu-west-1"
}

#resource "aws_s3_bucket" "my_bucket" {
 # bucket = "bucket-web-project-1"
  #acl    = "private"

  versioning {
    enabled = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::web-project/*"
    }
  ]
}
EOF
}
