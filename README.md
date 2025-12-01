# Azurestatefile
How to configure Terraform to host your remote statefile in Azure, including the setup of a basic network and compute environment, to get you started.
Note: Not git tool used, as basic principles and resources used
# Prerequisites
Install Azurecli
Add Azurecli to search path
Install Terraform
Add terraform to search path
# Intialise
Step 1. Login to Azure tenant
az login --tenant {Tenant_id}
az account list --output table
az account set -- subscription {subscription_id}
Add subscription_id and tenant_id to terraform.tfvars OR add to runtime command in subsequent steps.
Create/Choose repository location
Initilise terraform directory: Terraform init
# First stage terraform apply
Note: This will deploy and configure Terraform infrastructure - (Local Statefile)
Creates: Resource Group, Service Principle, KeyVault, RBAC roles and storage account/container etc (no encrypt)
terraform plan -out=tfplan
terraform apply tfplan
# Second stage terraform apply
Note: Will move statefile to Azure backend.
Requires: the name of storage account created in First Terraform apply
Uncomment the remote backend(.tf) sections (bootstrap) and update storage_account_name therein and add same to variable.tf.
terraform init -migrate-state
test: terraform plan -out=tfplan
# Third terrafrom apply
Note: Add extra Azure resources, keyvault, roles etc
rename bootstrap.tf to bootstrap.before3rd
rename bootstrap.beforemain to bootstrap.tf
Terraform plan -out=tfplan
Terraform apply tfplan
#
Bootstrapping complete
#
Leave bootstrap.tf OR can incorporate in main.tf below
# Optional STEPS
# Create Sample Network and Compute
rename main.afterbootstrapping main.tf
terraform plan -out=tfplan
Terraform apply tfplan

