terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

# specify the provider region
provider "aws" {
  region = "ca-central-1"

}

# the locals block is used to declare constants that 
# you can use throughout your codeo
locals {
  function_delete_note = "delete-note-30143058"
  function_get_note    = "get-notes-30143058"
  function_save_note   = "save-note-30143058"
  handler_delete_note  = "main.handler"
  handler_get_note     = "main.handler"
  handler_save_note    = "main.handler"
  artifact_get_note    = "${local.function_get_note}/artifact.zip"
  artifact_save_note   = "${local.function_save_note}/artifact.zip"
  artifact_delete_note = "${local.function_delete_note}/artifact.zip"
}

# Create an S3 bucket
# if you omit the name, Terraform will assign a random name to it
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "lambda" { bucket = "prosper-jori" }


data "archive_file" "lambda_zip_delete_note" {
  type        = "zip"
  source_file = "../functions/delete-note/main.py"
  output_path = "${local.function_delete_note} artifact.zip"
}

data "archive_file" "lambda_zip_get_note" {
  type        = "zip"
  source_file = "../functions/get-notes/main.py"
  output_path = "${local.function_get_note} artifact.zip"
}
data "archive_file" "lambda_zip_save_note" {
  type        = "zip"
  source_file = "../functions/save-note/main.py"
  output_path = "${local.function_save_note} artifact.zip"
}

# create a role for the Lambda function to assume
# every service on AWS that wants to call other AWS services should first assume a role and
# then any policy attached to the role will give permissions
# to the service so it can interact with other AWS services
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda_get_note" {
  name               = "iam-for-lambda-${local.function_get_note}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_save_note" {
  name               = "iam-for-lambda-${local.function_save_note}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_delete_note" {
  name               = "iam-for-lambda-${local.function_delete_note}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda_get_note" {

  # the artifact needs to be in the bucket first. Otherwise, this will fail.
  role             = aws_iam_role.lambda_get_note.arn
  function_name    = local.function_get_note
  filename         = data.archive_file.lambda_zip_get_note.output_path
  handler          = local.handler_get_note
  source_code_hash = data.archive_file.lambda_zip_get_note.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}
resource "aws_lambda_function" "lambda_delete_note" {

  # the artifact needs to be in the bucket first. Otherwise, this will fail.
  role             = aws_iam_role.lambda_delete_note.arn
  function_name    = local.function_delete_note
  filename         = data.archive_file.lambda_zip_delete_note.output_path
  handler          = local.handler_delete_note
  source_code_hash = data.archive_file.lambda_zip_delete_note.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}
resource "aws_lambda_function" "lambda_save_note" {

  # the artifact needs to be in the bucket first. Otherwise, this will fail.
  role             = aws_iam_role.lambda_save_note.arn
  function_name    = local.function_save_note
  filename         = data.archive_file.lambda_zip_save_note.output_path
  handler          = local.handler_save_note
  source_code_hash = data.archive_file.lambda_zip_delete_note.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

# create a policy for publishing logs to CloudWatch
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "get_note_logs" {
  name        = "lambda-logging-${local.function_get_note}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:Query" 
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.notes.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "save_note_logs" {
  name        = "lambda-logging-${local.function_save_note}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:PutItem"       
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.notes.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "delete_note_logs" {
  name        = "lambda-logging-${local.function_delete_note}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:DeleteItem"      
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.notes.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# attach the above policy to the function role
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_logs_delete" {
  role       = aws_iam_role.lambda_delete_note.name
  policy_arn = aws_iam_policy.delete_note_logs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_save" {
  role       = aws_iam_role.lambda_save_note.name
  policy_arn = aws_iam_policy.save_note_logs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_get" {
  role       = aws_iam_role.lambda_get_note.name
  policy_arn = aws_iam_policy.get_note_logs.arn
}

# output the name of the bucket after creation
output "bucket_name" {
  value = aws_s3_bucket.lambda.bucket
}

# read the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "notes" {
  name         = "lotion-30145690"
  billing_mode = "PROVISIONED"

  # up to 8KB read per second (eventually consistent)
  read_capacity = 1

  # up to 1KB per second
  write_capacity = 1

  # we only need a student id to find an item in the table; therefore, we 
  # don't need a sort key here
  hash_key  = "email"
  range_key = "id"

  # the hash_key data type is string
  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function_url" "get_note_function_url" {
  function_name      = aws_lambda_function.lambda_get_note.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep_alive", "date"]
  }
}

resource "aws_lambda_function_url" "delete_note_function_url" {
  function_name      = aws_lambda_function.lambda_delete_note.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep_alive", "date"]
  }
}

resource "aws_lambda_function_url" "save_note_function_url" {
  function_name      = aws_lambda_function.lambda_save_note.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST", "PUT"]
    allow_headers     = ["*"]
    expose_headers    = ["keep_alive", "date"]
  }
}


output "get_note_function_url" {
  value = aws_lambda_function_url.get_note_function_url.function_url
}


output "save_note_function_url" {
  value = aws_lambda_function_url.save_note_function_url.function_url
}

output "delete_note_function_url" {
  value = aws_lambda_function_url.delete_note_function_url.function_url
}




