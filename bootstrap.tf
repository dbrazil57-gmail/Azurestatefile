data "terraform_remote_state" "statefile" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.resource_group_state
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = var.key
  }
}

provider "azurerm" {
  features {}

  client_id       = data.terraform_remote_state.statefile.outputs.sp_client_id
  client_secret   = data.terraform_remote_state.statefile.outputs.sp_client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

## Durimg bootstrtaping ## - END

# Create Service Principal
resource "azuread_application" "terraform_app" {
  display_name = "terraform-deployer"
}

resource "azuread_service_principal" "terraform_sp" {
  client_id = azuread_application.terraform_app.client_id
}

resource "azuread_application_password" "terraform_sp_password" {
  application_id = azuread_application.terraform_app.id
  display_name   = "terraform-client-secret"
  start_date     = timestamp()
  end_date       = timeadd(timestamp(), "8760h")

lifecycle {
    ignore_changes = [
      start_date,
      end_date,
    ]
  }
}

## These need bootstrapping provider ## - START
resource "azurerm_key_vault_secret" "sp_client_id" {
  name         = "sp-client-id"
  value        = azuread_application.terraform_app.client_id
  key_vault_id = azurerm_key_vault.statefile.id
}

resource "azurerm_key_vault_secret" "sp_client_secret" {
  name         = "sp-client-secret"
  value        = azuread_application_password.terraform_sp_password.value
  key_vault_id = azurerm_key_vault.statefile.id
}
## These need bootstrapping provider ## - END

# Random suffix for namingbv
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Create Key Vault
resource "azurerm_key_vault" "statefile" {
  name                        = "tfstate-keyvault-${random_string.suffix.result}"
  location                    = local.location
  resource_group_name         = var.resource_group_state
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  rbac_authorization_enabled  = true
}

# Assign Contributor role to SP
resource "azurerm_role_assignment" "terraform_sp_role" {
  principal_id         = azuread_service_principal.terraform_sp.object_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.primary.id
  depends_on = [azuread_service_principal.terraform_sp]
}

# Grant SP access to Key Vault
resource "azurerm_role_assignment" "terraform_sp_kv_access" {
  scope                = azurerm_key_vault.statefile.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_service_principal.terraform_sp.object_id

  depends_on = [azurerm_key_vault.statefile]
}

resource "azurerm_role_assignment" "sp_user_access_admin" {
  principal_id         = azuread_service_principal.terraform_sp.object_id
  role_definition_name = "User Access Administrator"
  scope                = azurerm_key_vault.statefile.id
}

## If Using a Managment Group ##
#resource "azurerm_role_assignment" "terraform_sp_mg_access" {
  #principal_id         = azuread_service_principal.terraform_sp.object_id
  #role_definition_name = "Management Group Contributor"
  #scope                = azurerm_management_group.root.id

  #depends_on = [azuread_service_principal.terraform_sp]
#}

## If SP needs to access the statefile for data type definitions ##
#resource "azurerm_role_assignment" "terraform_sp_storage_access" {
  #scope                = azurerm_storage_account.tfstate.id
  #role_definition_name = "Storage Blob Data Reader"
  #principal_id         = azuread_service_principal.terraform_sp.object_id

  #depends_on = [azurerm_key_vault.statefile]
#}

# Create Key Vault Key
resource "azurerm_key_vault_key" "statefile" {
  name         = var.tfstate-key
  key_vault_id = azurerm_key_vault.statefile.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"
  ]
}

resource "azurerm_user_assigned_identity" "tfstate_uami" {
  name                = "tfstate-uami"
  resource_group_name = var.resource_group_state           
  location            = local.location
}

resource "azurerm_role_assignment" "uami_key_access" {
  principal_id         = azurerm_user_assigned_identity.tfstate_uami.principal_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  scope                = azurerm_key_vault.statefile.id
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_state
  location = local.location
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstatestore${random_string.suffix.result}"
  resource_group_name      = var.resource_group_state           
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.tfstate_uami.id]
  }

  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.statefile.id
    user_assigned_identity_id = azurerm_user_assigned_identity.tfstate_uami.id
  }

  infrastructure_encryption_enabled = true
  #public_network_access_enabled    = false # Afterbootstrap
  allow_nested_items_to_be_public   = false
  min_tls_version                   = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags

  depends_on = [
    azurerm_user_assigned_identity.tfstate_uami,
    azurerm_role_assignment.uami_key_access,
    azurerm_key_vault_key.statefile
  ]
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.tfstate.name}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.tfstate.name}"
  container_access_type = "private"
}

output "sp_client_id" {
  value = azuread_application.terraform_app.client_id
}

# Added security ##
#resource "azurerm_management_lock" "tfstate_lock" {
  #name       = "tfstate-lock"
  #scope      = azurerm_storage_account.tfstate.id
  #lock_level = "CanNotDelete"
#}

output "sp_client_secret" {
  value     = azuread_application_password.terraform_sp_password.value
  sensitive = true
}

output "sp_object_id" {
  value = azuread_service_principal.terraform_sp.object_id
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}