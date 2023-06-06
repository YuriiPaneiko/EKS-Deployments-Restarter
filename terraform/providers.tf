provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.env.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.env.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.env.token
}

