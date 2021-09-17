
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

variable "acr_subscription_id" {
  type = string

  # TODO use environment varariable
  default = "<CHANGE_HERE>"
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

#data "azurerm_user_assigned_identity" "assigned_identity_acr_pull" {
# provider            = azurerm.acr_sub
# name                = "User_ACR_pull"
# resource_group_name = "desafio-devops"
#}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = "desafio-devops"
  location            = "East US"

  name = "User_ACR_pull"
}

# App service plan, define set of computing resources for the web app to run
resource "azurerm_app_service_plan" "desafio-devops-service-plan" {
 name                = "desafio-devops-service-plan"
 location            = "East US"
 resource_group_name = "desafio-devops"
 kind                = "Linux"
 reserved            = true

 sku {
   tier     = "PremiumV2"
   size     = "P2v2"
   capacity = "3" # Specifies the number of workers associated with this App Service Plan.
 }
}

locals {
 env_variables = {
   DOCKER_ENABLE_CI                      = true
   DOCKER_REGISTRY_SERVER_URL            = "https://ldconsulting.azurecr.io"
   DOCKER_REGISTRY_SERVER_USERNAME       = "ldconsulting"
   DOCKER_REGISTRY_SERVER_PASSWORD       = "<CHANGE_THIS>"
 }
}

# App service 
resource "azurerm_app_service" "desafio-devops-service-container" {
 name                    = "desafio-devops-service-container"
 location                = "East US"
 resource_group_name     = "desafio-devops"
 app_service_plan_id     = azurerm_app_service_plan.desafio-devops-service-plan.id
 https_only              = true
 client_affinity_enabled = true
 site_config {
   scm_type  = "VSTSRM"
   always_on = "true"

   # Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), 
   # a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) 
   # or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
   linux_fx_version  = "DOCKER|ldconsulting.azurecr.io/desafio-devops:latest" 

   # health check required in order that internal app service plan loadbalancer do not loadbalance on instance down
   health_check_path = "/health" 
 }

 identity {
   type         = "SystemAssigned, UserAssigned"
   identity_ids = [azurerm_user_assigned_identity.example.id]
 }

 app_settings = local.env_variables 
}

# setup staging slot
resource "azurerm_app_service_slot" "desafio-devops-service-container_staging" {
 name                    = "staging"
 app_service_name        = azurerm_app_service.desafio-devops-service-container.name
 location                = "East US"
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
   identity_ids = [azurerm_user_assigned_identity.example.id]
 }

 app_settings = local.env_variables
}

# setup monitoring
# env variables needed:
# AZURE_MONITOR_INSTRUMENTATION_KEY = azurerm_application_insights.desafio-devops-insight.instrumentation_key
resource "azurerm_application_insights" "desafio-devops-insight" {
 name                = "desafio-devops-insight"
 location            = "East US"
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