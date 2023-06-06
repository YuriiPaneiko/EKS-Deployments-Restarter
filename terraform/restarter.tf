locals {
  deployments_to_rotate = var.deployments_to_rotate
}

resource "aws_security_group" "restarter" {
  name        = "${var.environment}-deployments-restarter-sg"
  description = "Allow outbount traffic"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "restarter" {
  name = "${var.environment}-deployments-restarter-role"

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

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.restarter.name
}

resource "aws_iam_policy" "policy_one" {
  name = "${var.environment}-eks-cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["eks:DescribeCluster", "sts:GetCallerIdentity"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy" {
  policy_arn = aws_iam_policy.policy_one.arn
  role       = aws_iam_role.restarter.name
}

resource "aws_lambda_function" "restarter" {
  function_name = "${var.environment}-deployments-restarter"
  role          = aws_iam_role.restarter.arn
  architectures = ["x86_64"]
  timeout       = 300
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "../../../../utilities/recreate-pod-secrets-rotate/dist/reko.zip"
  vpc_config {
    security_group_ids = [aws_security_group.restarter.id]
    subnet_ids         = data.aws_subnets.private.ids
  }
  environment {
    variables = {
      CLUSTER_NAME          = var.cluster_name
      REGION                = var.aws_region
      NAMESPACE             = "${var.environment}"
      DEPLOYMENTS_TO_ROTATE = ""
    }
  }
}

resource "aws_lambda_permission" "cw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restarter.function_name
  principal     = "logs.${var.aws_region}.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  source_arn    = "${data.aws_cloudwatch_log_group.log_group.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "example_subscription_filter" {
  depends_on      = [aws_lambda_permission.cw]
  name            = "${var.environment}-restarter-filter"
  log_group_name  = data.aws_cloudwatch_log_group.log_group.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.restarter.arn
}


