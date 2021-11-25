# create a Kubernetes secret with the username and the password of the Elasticsearch user in each given namespace
resource kubernetes_secret elasticsearch_restore {
  count = var.elasticsearch_backup_restore_enabled ? 1 : 0
  type = "Opaque"
  metadata {
    name = "${var.elasticsearch_cluster_name}-restore"
    namespace = module.namespace.k8s_namespace_name
    labels = {
      "app.kubernetes.io/name" = var.elasticsearch_cluster_name
      "app.kubernetes.io/component" = "secret"
      "app.kubernetes.io/part-of" = var.solution_name
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  # we are explicitly using binary_data with base64encode() to prevent sensitive data from showing up in terraform state
  binary_data = {
    "azure.client.default.account" = base64encode(data.azurerm_storage_account.snapshot[0].name)
    "azure.client.default.key" = base64encode(data.azurerm_storage_account.snapshot[0].primary_access_key)
  }
}


