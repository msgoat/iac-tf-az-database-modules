output elasticsearch_service_name {
  description = "Name of the Kubernetes service referring to this elasticsearch cluster"
  value = "${var.elasticsearch_cluster_name}-master.${var.kubernetes_namespace_name}"
}

output elasticsearch_service_port {
  description = "Port of the Kubernetes service referring to this elasticsearch cluster"
  value = "9200"
}