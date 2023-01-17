output elasticsearch_service_name {
  description = "Name of the Kubernetes service referring to this elasticsearch cluster"
  value = local.es_hostname
}

output elasticsearch_service_port {
  description = "Port of the Kubernetes service referring to this elasticsearch cluster"
  value = local.es_port
}

output elasticsearch_service_url {
  description = "URL of the Kubernetes service referring to this elasticsearch cluster"
  value = local.es_url
}

output elasticsearch_credentials_kv_secret_id {
  description = "Unique identifier of the Key Vault secret holding username and password to access this elasticsearch cluster"
  value = azurerm_key_vault_secret.elasticsearch.id
}

output elasticsearch_credentials_k8s_secret_name {
  description = "Name of the Kubernetes secret holding username and password to access this elasticsearch cluster"
  value = kubernetes_secret.elasticsearch.metadata[0].name
}
