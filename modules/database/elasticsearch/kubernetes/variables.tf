variable region_name {
  description = "The Azure region to deploy into."
  type = string
}

variable region_code {
  description = "The code of Azure region to deploy into (supposed to be a meaningful abbreviation of region_name."
  type = string
}

variable common_tags {
  description = "Map of common tags to be attached to all managed Azure resources"
  type = map(string)
}

variable solution_name {
  description = "Name of this Azure solution"
  type = string
}

variable solution_stage {
  description = "Stage of this Azure solution"
  type = string
}

variable solution_fqn {
  description = "Fully qualified name of this Azure solution"
  type = string
}

variable resource_group_name {
  description = "The name of the resource group supposed to own all allocated resources"
  type = string
}

variable resource_group_location {
  description = "The location of the resource group supposed to own all allocated resources"
  type = string
}

variable aks_cluster_id {
  description = "Unique identifier of the AKS cluster"
  type = string
}

variable kubernetes_namespace_name {
  description = "Name of the Kubernetes namespace supposed to host the ElasticSearch instance"
  type = string
}

variable helm_release_name {
  description = "Name of the Helm release used to deploy the ingress controller"
  type = string
  default = "elasticsearch"
}

variable elasticsearch_cluster_name {
  description = "Name of the ElasticSearch cluster"
  type = string
  default = "elasticsearch"
}

variable elasticsearch_cluster_size {
  description = "Number of nodes the ElasticSearch cluster should contain; should not be less than 3"
  type = number
  default = 3
  validation {
    condition = var.elasticsearch_cluster_size >= 3
    error_message = "Expected at least 3 elastic search cluster nodes."
  }
}

variable elasticsearch_node_cpu {
  description = "Number of cores which should be assigned to each ElasticSearch cluster node; should not be less than 1"
  type = number
  default = 1
  validation {
    condition = var.elasticsearch_node_cpu >= 1 && var.elasticsearch_node_cpu <= 2
    error_message = "Expected between 1 and 2 cores for each elasticsearch node."
  }
}

variable elasticsearch_node_ram {
  description = "Memory in gigabytes which should be assigned to each ElasticSearch cluster node; should not be less than 2"
  type = number
  default = 2
  validation {
    condition = var.elasticsearch_node_ram >= 2 && var.elasticsearch_node_ram <= 4
    error_message = "Expected between 2 and 4 GB RAM for each elasticsearch node."
  }
}

variable elasticsearch_node_storage_size {
  description = "Storage size allocated by each ElasticSearch cluster node in GB"
  type = number
  default = 30
}

variable elasticsearch_node_storage_sku {
  description = "Storage SKU allocated by each ElasticSearch cluster node; supported values are: Standard, Premium"
  type = string
  default = "Standard"
  validation {
    condition = var.elasticsearch_node_storage_sku == "Standard" || var.elasticsearch_node_storage_sku == "Premium"
    error_message = "Expected Standard or Premium storage SKU for each Elasticsearch node."
  }
}

variable key_vault_id {
  description = "Unique identifier of a Key Vault instance supposed to manage all secrets and encryption keys"
  type = string
}

variable secret_namespace_names {
  description = "Names of the Kubernetes namespaces supposed to get an secret with Elasticsearch username and password"
  type = list(string)
  default = []
}

variable public_access_enabled {
  description = "Controls if public network access is allowed for this server"
  type = bool
  default = false
}

variable public_access_host {
  description = "Hostname of the first Front Door or Application Gateway to forward traffic to the AKS cluster"
  type = string
  default = ""
}

variable elasticsearch_security_enabled {
  description = "Controls if basic security is enabled; requires activation of TLS as well (which means TLS certificates!)"
  type = bool
  default = false
}

variable elasticsearch_backup_restore_enabled {
  description = "Controls if snapshot should be restored from Azure Storage container"
  type = bool
  default = false
}

variable elasticsearch_snapshot_id {
  description = "Unique identifier of a blob storage account providing elasticsearch snapshots/backups"
  type = string
  default = ""
}

variable elasticsearch_image_name {
  description = "Custom docker image name of Elasticsearch image with Azure Repository Plugin"
  type = string
  default = ""
}

variable elasticsearch_image_tag {
  description = "Custom docker image tag of Elasticsearch image with Azure Repository Plugin"
  type = string
  default = ""
}

variable node_group_workload_class {
  description = "Class of the AKS node group Elasticsearch should be hosted on"
  type = string
  default = ""
}

variable topology_spread_strategy {
  description = "Strategy to use regarding distribution of cluster nodes across node / availability zones; possible values are: none, soft and hard"
  type = string
  default = "hard"
}
