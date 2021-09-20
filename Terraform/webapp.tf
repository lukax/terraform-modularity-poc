
# With this configuration file we are able to deploy from code, an high available application in an Azure app service 
# with the required monitoring for production use with the possibility of using blue/green deployment 
# with the staging slot to avoid any downtime during your code deployment.
# once applied, you can see the resources created in azure:
# App service plan: desafio-devops-service-plan
# App service: desafio-devops-service-container
# App insight: desafio-devops-appinsights

locals {
  env_variables = {
    DOCKER_ENABLE_CI                = true
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.acr.name}.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    APPINSIGHTS_INSTRUMENTATIONKEY  = azurerm_application_insights.appinsights.instrumentation_key
  }
}

variable "AZURE_ACCOUNT_ID" {
  type    = string
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.77.0"
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
  subscription_id = var.AZURE_ACCOUNT_ID
  features {}
  skip_provider_registration = "true"

}
provider "azuread" {
}

resource "azurerm_resource_group" "dd" {
  name     = "desafio-devops"
  location = "East US"
}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = azurerm_resource_group.dd.name
  location            = azurerm_resource_group.dd.location

  name = "User_ACR_pull"
}

resource "azurerm_container_registry" "acr" {
  name                = "desafiodevopsacr"
  resource_group_name = azurerm_resource_group.dd.name
  location            = azurerm_resource_group.dd.location
  sku                 = "Premium"
  admin_enabled       = true
  
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.example.id
    ]
  }

  # encryption {
    # enabled = false
    # key_vault_key_id   = data.azurerm_key_vault_key.example.id
    # identity_client_id = azurerm_user_assigned_identity.example.client_id
  # }

}

# App service plan, define set of computing resources for the web app to run
resource "azurerm_app_service_plan" "desafio-devops-service-plan" {
  name                = "desafio-devops-service-plan"
  location            = azurerm_resource_group.dd.location
  resource_group_name = azurerm_resource_group.dd.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier     = "PremiumV2"
    size     = "P2v2"
    capacity = "3" # Specifies the number of workers associated with this App Service Plan.
  }
}

# App service 
resource "azurerm_app_service" "appsvc_default" {
  name                    = "desafio-devops-service-container"
  location                = azurerm_resource_group.dd.location
  resource_group_name     = azurerm_resource_group.dd.name
  app_service_plan_id     = azurerm_app_service_plan.desafio-devops-service-plan.id
  https_only              = true
  client_affinity_enabled = true
  site_config {
    scm_type  = "VSTSRM"
    always_on = "true"

    # Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), 
    # a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) 
    # or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.name}.azurecr.io/desafio-devops:prod"

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
resource "azurerm_app_service_slot" "appsvc_staging" {
  name                    = "staging"
  app_service_name        = azurerm_app_service.appsvc_default.name
  location                = azurerm_resource_group.dd.location
  resource_group_name     = azurerm_resource_group.dd.name
  app_service_plan_id     = azurerm_app_service_plan.desafio-devops-service-plan.id
  https_only              = true
  client_affinity_enabled = true
  site_config {
    scm_type  = "VSTSRM"
    always_on = "true"

    # Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), 
    # a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) 
    # or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.name}.azurecr.io/desafio-devops:latest"

    # health check required in order that internal app service plan loadbalancer do not loadbalance on instance down
    health_check_path = "/health"
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }

  app_settings = local.env_variables
}

# manages an Azure Container Registry Webhook for Production.
resource "azurerm_container_registry_webhook" "webhook_prod" {
  name                = "defaultwebhookprod"
  registry_name       = azurerm_container_registry.acr.name 
  resource_group_name = azurerm_resource_group.dd.name
  location            = azurerm_resource_group.dd.location

  service_uri = "https://${azurerm_app_service.appsvc_default.site_credential.0.username}:${azurerm_app_service.appsvc_default.site_credential.0.password}@${azurerm_app_service.appsvc_default.name}.scm.azurewebsites.net/docker/hook"
  status      = "enabled"
  scope       = "desafio-devops:prod"
  actions     = ["push"]
  custom_headers = {
    "Content-Type" = "application/json"
  }
}

# manages an Azure Container Registry Webhook for Staging/QA.
resource "azurerm_container_registry_webhook" "webhook_staging" {
  name                = "defaultwebhookstaging"
  registry_name       = azurerm_container_registry.acr.name 
  resource_group_name = azurerm_resource_group.dd.name
  location            = azurerm_resource_group.dd.location

  service_uri = "https://${azurerm_app_service_slot.appsvc_staging.site_credential.0.username}:${azurerm_app_service_slot.appsvc_staging.site_credential.0.password}@${azurerm_app_service.appsvc_default.name}-${azurerm_app_service_slot.appsvc_staging.name}.scm.azurewebsites.net/docker/hook"
  status      = "enabled"
  scope       = "desafio-devops:latest"
  actions     = ["push"]
  custom_headers = {
    "Content-Type" = "application/json"
  }
}

# setup monitoring
resource "azurerm_application_insights" "appinsights" {
  name                = "desafio-devops-appinsights"
  resource_group_name = azurerm_resource_group.dd.name
  location            = azurerm_resource_group.dd.location
  application_type    = "Node.JS" # Depends on the application
  disable_ip_masking  = true
}
