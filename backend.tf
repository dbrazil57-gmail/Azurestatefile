## Bootstrap ##
terraform {
  backend "local" {}
}

## Add after bootstraping (with backend.hcl file)
#terraform {
  #backend "azurerm" {
    #resource_group_name  = "tfstate-rg"
    #storage_account_name = "your-storage-account"
    #container_name       = "tfstate"
    #key                  = "terraform.tfstate"
  #}
#}