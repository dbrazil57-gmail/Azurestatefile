resource "azurerm_resource_group" "compute" {
  name     = local.resource_group_compute
  location = local.location
  tags     = local.tags
}

resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "${local.vm_server1}-nic"
  location            = local.location
  resource_group_name = local.resource_group_compute

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

resource "random_password" "vm_admin_password" {
  length  = 16
  special = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "${local.vm_server1}-admin-password"
  value        = random_password.vm_admin_password.result
  key_vault_id = azurerm_key_vault.statefile.id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = local.vm_server1
  location            = local.location
  resource_group_name = local.resource_group_compute
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = azurerm_key_vault_secret.vm_admin_password.value
  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic.id
  ]

  os_disk {
    name                 = "windows-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = local.tags
}

resource "azurerm_virtual_machine_extension" "set_timezone_and_locale" {
  name                 = "set-timezone-and-locale"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"tzutil /s '${local.timezone}'; Set-WinSystemLocale ${local.locale}; Set-Culture ${local.locale}; Set-WinUserLanguageList ${local.locale} -Force\""
    }
  SETTINGS

  depends_on = [azurerm_windows_virtual_machine.windows_vm]
}