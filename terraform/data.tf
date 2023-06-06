data "aws_cloudwatch_log_group" "log_group" {
    name = "/aws/lambda/secrets-rotator"
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.vpc_name}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc.id}"]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_eks_cluster" "env" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "env" {
  name = var.cluster_name
}