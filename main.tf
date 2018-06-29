variable "aws_profile" {
  default = "money"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "slack_webhook" {
  default = "https://hooks.slack.com/services/TOKEN"
}

variable "schedule" {
  default = "rate(1 minute)"
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

resource "aws_iam_role" "lambda" {
  name = "TrendingSlackBotLambdaRole"

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

resource "aws_iam_role_policy" "lambda" {
  name = "TrendingSlackBotAllowCloudwatch"
  role = "${aws_iam_role.lambda.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "bot" {
  filename      = "deployment.zip"
  function_name = "TrendingSlackBot"
  description   = "Trending Slack Bot"
  role          = "${aws_iam_role.lambda.arn}"
  handler       = "main"
  runtime       = "go1.x"

  environment {
    variables = {
      SLACK_WEBHOOK = "${var.slack_webhook}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "scheduled-rule" {
  name                = "TrendingSlackBotScheduledRule"
  schedule_expression = "${var.schedule}"
}

resource "aws_cloudwatch_event_target" "scheduled_run_target" {
  rule      = "${aws_cloudwatch_event_rule.scheduled-rule.name}"
  target_id = "TrendingSlackBotScheduledRule"
  arn       = "${aws_lambda_function.bot.arn}"
}

resource "aws_lambda_permission" "allow-cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.bot.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.scheduled-rule.arn}"
}
