locals {
  restarter_role = [
    {
      rolearn  = aws_iam_role.restarter.arn
      username = "restart-deployment"
      groups   = ["dev-access"]
    }
  ]
}

data "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [kubernetes_manifest.rolebinding_internal_development_my_namespace_binding]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(toset(concat(yamldecode(lookup(data.kubernetes_config_map_v1.aws_auth.data, "mapRoles", "[]")), local.restarter_role)))
  }
  force = true
}
