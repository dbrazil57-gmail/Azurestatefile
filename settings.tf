locals {
  location                = "Australia East"
  environment             = "test"
  resource_group_name     = "network-rg"
  resource_group_compute  = "compute-rg"
  vm_server1              = "windows-server1"

  region_settings = {
    "Australia East" = {
      timezone = "AUS Eastern Standard Time"
      locale   = "en-AU"
    }
    "East US" = {
      timezone = "Eastern Standard Time"
      locale   = "en-US"
    }
    "West Europe" = {
      timezone = "W. Europe Standard Time"
      locale   = "en-GB"
    }
  }

  timezone = lookup(local.region_settings[local.location], "timezone", "UTC")
  locale   = lookup(local.region_settings[local.location], "locale", "en-US")

  tags = {
    environment = local.environment
  }

  address_space       = "10.0.0.0/16"  
  bastion_subnet_cidr = "10.0.1.0/27"
  public_subnet_cidr  = "10.0.1.32/27"
  peer_address_space  = "10.1.0.0/16"
  private_subnet_cidr = "10.1.1.0/24"
}