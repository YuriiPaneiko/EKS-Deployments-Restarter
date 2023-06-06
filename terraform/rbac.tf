resource "kubernetes_manifest" "role_internal_development_full_namespace" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "Role"
    "metadata" = {
      "name" = "dev-access"
      "namespace" = "${var.environment}"
    }
    "rules" = [
      {
        "apiGroups" = [
          "*",
        ]
        "resources" = [
          "pods",
        ]
        "verbs" = [
          "get",
          "delete",
          "watch",
          "list",
          "update",
          "patch"
        ]
      },
      {
        "apiGroups" = [
          "*",
        ]
        "resources" = [
          "deployments",
        ]
        "verbs" = [
          "get",
          "delete",
          "watch",
          "list",
          "update",
          "patch"
        ]
      },
      {
        "apiGroups" = [
          "*",
        ]
        "resources" = [
          "deployments/scale",
        ]
        "verbs" = [
          "get",
          "delete",
          "watch",
          "list",
          "update",
          "patch"
        ]
      },
      {
        "apiGroups" = [
          "*",
        ]
        "resources" = [
          "pods/log",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
      {
        "apiGroups" = [
          "*",
        ]
        "resources" = [
          "namespaces",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "rolebinding_internal_development_my_namespace_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "RoleBinding"
    "metadata" = {
      "name" = "dev-access"
      "namespace" = "${var.environment}"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "Role"
      "name" = "dev-access"
    }
    "subjects" = [
      {
        "apiGroup" = "rbac.authorization.k8s.io"
        "kind" = "Group"
        "name" = "dev-access"
      },
    ]
  }
}

