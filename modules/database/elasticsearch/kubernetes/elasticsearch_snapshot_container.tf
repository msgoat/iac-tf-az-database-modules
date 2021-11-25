locals {
  # "/subscriptions/5945938d-2ee8-4229-ac6a-b0d1ff422981/resourceGroups/rg-westeu-echs15apps-dev-stage/providers/Microsoft.Storage/storageAccounts/stwesteuechs15appsdev"
  storage_account_id_parts = var.elasticsearch_backup_restore_enabled ? split("/", var.elasticsearch_snapshot_id) : []
  storage_account_resource_group_name = var.elasticsearch_backup_restore_enabled ? local.storage_account_id_parts[4] : ""
  storage_account_name = var.elasticsearch_backup_restore_enabled ? local.storage_account_id_parts[8] : ""
}

data azurerm_storage_account snapshot {
  count = var.elasticsearch_backup_restore_enabled ? 1 : 0
  name = local.storage_account_name
  resource_group_name = local.storage_account_resource_group_name
}