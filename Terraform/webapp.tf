
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate13637"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
 #version         = "=2.46.0"
 subscription_id = var.acr_subscription_id
 features {}
 skip_provider_registration = "true"

 # tenant_id         = "<azure_subscription_tenant_id>"
 # client_id         = "<service_principal_appid>"
 # client_secret     = "<service_principal_password>"

}
provider "azuread" {
 # version = "=0.7.0"
}

data "azurerm_user_assigned_identity" "assigned_identity_acr_pull" {
 provider            = azurerm.acr_sub
 name                = "User_ACR_pull"
 resource_group_name = "desafio-devops"
}

# App service plan, define set of computing resources for the web app to run
resource "azurerm_app_service_plan" "desafio-devops-service-plan" {
 name                = "desafio-devops-service-plan"
 location            = "US East"
 resource_group_name = "desafio-devops"
 kind                = "Linux"
 reserved            = true

 sku {
   tier     = "PremiumV2"
   size     = "P2v2"
   capacity = "3"
 }
}

locals {
 env_variables = {
   DOCKER_REGISTRY_SERVER_URL            = "https://ldconsulting.azurecr.io"
   DOCKER_REGISTRY_SERVER_USERNAME       = "ldconsulting"
   #DOCKER_REGISTRY_SERVER_PASSWORD       = "******"
 }
}

# App service 
resource "azurerm_app_service" "desafio-devops-service-container" {
 name                    = "desafio-devops-service-container"
 location                = "US East"
 resource_group_name     = "desafio-devops"
 app_service_plan_id     = azurerm_app_service_plan.desafio-devops-service-plan.id
 https_only              = true
 client_affinity_enabled = true
 site_config {
   scm_type  = "VSTSRM"
   always_on = "true"

   linux_fx_version  = "DOCKER|arc01.azurecr.io/myapp:latest" #define the images to usecfor you application

   health_check_path = "/health" # health check required in order that internal app service plan loadbalancer do not loadbalance on instance down
 }

 identity {
   type         = "SystemAssigned, UserAssigned"
   identity_ids = [data.azurerm_user_assigned_identity.assigned_identity_acr_pull.id]
 }

 app_settings = local.env_variables 
}

# setup staging slot
resource "azurerm_app_service_slot" "desafio-devops-service-container_staging" {
 name                    = "staging"
 app_service_name        = azurerm_app_service.desafio-devops-service-container.name
 location                = "US East"
 resource_group_name     = "desafio-devops"
 app_service_plan_id     = azurerm_app_service_plan.desafio-devops-service-plan.id
 https_only              = true
 client_affinity_enabled = true
 site_config {
   scm_type          = "VSTSRM"
   always_on         = "true"
   health_check_path = "/login"
 }

 identity {
   type         = "SystemAssigned, UserAssigned"
   identity_ids = [data.azurerm_user_assigned_identity.assigned_identity_acr_pull.id]
 }

 app_settings = local.env_variables
}

# setup monitoring
# env variables needed:
# AZURE_MONITOR_INSTRUMENTATION_KEY = azurerm_application_insights.desafio-devops-insight.instrumentation_key
resource "azurerm_application_insights" "desafio-devops-insight" {
 name                = "desafio-devops-insight"
 location            = "US East"
 resource_group_name = "desafio-devops"
 application_type    = "Node.JS" # Depends on the application
 disable_ip_masking  = true
 retention_in_days   = 730
}


# Once applied, you can see the resources created in azure:
# - App service plan: desafio-devops-service-plan
# App service: desafio-devops-service-container
# App insight: desafio-devops-insight

# Now we are able to deploy from code, an high available application in an Azure app service 
# with the required monitoring for production use with the possibility of using blue/green deployment 
# with the staging slot to avoid any downtime during your code deployment.