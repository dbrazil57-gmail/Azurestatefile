variable "subscription_id" {
  description = "Azure Subscription ID to associate with the management group"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
}

variable "resource_group_state" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
  default     = "tfstate-rg"
}

variable "storage_account_name" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
  default     = "your-storage-account"
}

variable "container_name" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
  default     = "tfstate"
}

variable "key" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
  default     = "terraform.tfstate"
}
  
variable "tfstate-key" {
  description = "Azure Tenant ID to associate with the management group"
  type        = string
  default     = "tfstate-key"
}