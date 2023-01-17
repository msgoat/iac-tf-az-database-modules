locals {
  target_namespace_names = concat(var.secret_namespace_names, [ var.kubernetes_namespace_name ])
}

# create a Kubernetes secret with the username and the password of the Elasticsearch user in each given namespace
resource kubernetes_secret elasticsearch {
  count = length(local.target_namespace_names)
  type = "Opaque"
  metadata {
    name = var.elasticsearch_cluster_name
    namespace = local.target_namespace_names[count.index]
    labels = {
      "app.kubernetes.io/name" = var.elasticsearch_cluster_name
      "app.kubernetes.io/component" = "secret"
      "app.kubernetes.io/part-of" = var.solution_name
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  # we are explicitly using binary_data with base64encode() to prevent sensitive data from showing up in terraform state
  binary_data = {
    elasticsearch-user = base64encode(random_string.user.result)
    elasticsearch-password = base64encode(random_password.password.result)
  }
}