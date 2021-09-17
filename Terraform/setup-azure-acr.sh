#!/bin/bash

RESOURCE_GROUP_NAME=desafio-devops
ACR_REGISTRY_NAME=ldconsulting
APP_ID=CHANGE_THIS # TODO <insert here>

az acr create --name $ACR_REGISTRY_NAME --resource-group $RESOURCE_GROUP_NAME --sku Standard

# Login to ACR
# az acr login --name $ACR_REGISTRY_NAME

# Save the login server to a variable
# LOGIN_SERVER=$(az acr show --name $ACR_REGISTRY_NAME --query loginServer --output tsv)

# Save the registry ID to a variable
# ACR_ID=$(az acr show --name $ACR_REGISTRY_NAME --query id --output tsv)

# Assign AcrPush role to the Service Principal
# az role assignment create --assignee $(cat .secret/appId.txt) --scope ${ACR_ID} --role AcrPush
