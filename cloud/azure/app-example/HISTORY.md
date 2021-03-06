# v0.1.6

## Wrapping it all up with the first app deploy

Create the infrasctruture in Azure Cloud:
```
$ cd Terraform && terraform apply
```

Setup Azure Pipelines by referencing ```azure-pipelines.yml``` file.

Do a git push on the ```develop``` branch and wait for the CI/CD to trigger a new build, after that you should have the app running in a few minutes!

You can also deploy the app through the command line using docker compose directly:
```
$ docker-compose -f docker-compose.yml -f docker-compose.override.prod.yml build
$ az acr login --name "desafiodevopsacr" --username "desafiodevopsacr"
$ docker-compose -f docker-compose.yml -f docker-compose.override.prod.yml push
```


# v0.1.5

## Setting up monitoring with Azure Application Insights

Azure Application Insights allows to collect traces, requests and exceptions very easily and build analytics queries and dashboard for visualization it comes with a Python SDK that supports direct integration with the Flask Framework.

* set up Application Insights for Flask web app
* add Terraform resource for Application Insights and load ```APPINSIGHTS_INSTRUMENTATIONKEY``` environment variable inside Flask web app
* click on the Analytics button in the Azure portal to see generated data
 
To execute a simple query over past 1 hour:
```
$ az monitor app-insights query --resource-group desafio-devops --app desafio-devops-appinsights --analytics-query 'requests | summarize count() by bin(timestamp, 1h)' --offset 1h
```

View metadata for all the available metrics:
```
$ az monitor app-insights metrics get-metadata --resource-group desafio-devops --app desafio-devops-appinsights
```

View the count of failed requests:
```
$ az monitor app-insights metrics show --resource-group desafio-devops --app desafio-devops-appinsights --metric requests/failed
```

# v0.1.4

## Building a CI/CD with Azure Pipelines 

* Connect Azure DevOps to the GitHub repository
* Configure the pipeline to build app Docker-compose image
* Set a branch trigger master/develop for either production/QA following the Git Flow branching model
* Select Azure subscription and container registry
* Set $(AZURE_SUBSCRIPTION) and $(AZURE_CONTAINER_REGISTRY) environment [variables for the pipeline](https://docs.microsoft.com/pt-br/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch)
* Save the pipeline YAML file and run

# v0.1.3

## Tagging Docker images and deploying to production

Tag the docker image:
```
$ docker tag desafio-devops:latest desafiodevopsacr.azurecr.io/desafio-devops:latest
```

Push the docker image to Azure Container Registry:
```
$ docker push desafiodevopsacr.azurecr.io/desafio-devops:latest
```

Test the production app with a sample HTTP request
```
$ curl -sv https://desafio-devops-service-container.azurewebsites.net/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"first post!","content_id":1}'
```

# v0.1.2

## Setting up IaaS with Azure Cloud and IaC with Terraform

* add `Terraform/webapp.tf` file
 
Steps to get Terraform working with Azure Cloud:
* [configure Azure Cloud shell with bash](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash)
* [configure Terraform state storage in Azure Cloud](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)

To setup Azure Container Registry:
```
$ ./Terraform/setup-azure-acr.sh
```

To setup state storage for Terraform in Azure Cloud:
```
$ ./Terraform/setup-azure-storage.sh
```
Terraform state is used to reconcile deployed resources with Terraform configurations. State allows Terraform to know what Azure resources to add, update, or delete.

In order to initialize the Terraform configuration:
``` 
$ terraform init 
```

And to run the Terraform configuration:
``` 
$ terraform apply 
```

# v0.1.1

## Bootstrapping

* add Dockerfile with an Alpine-based Docker image for Python 3.9.6, set a working directory and add environment variables, updated pip, copied over requirements.txt file, installed dependencies and copied the project files itself.
* setup entrypoint.sh file which we can perform some verifications and later run the Gunicorn HTTP server.

To build the docker image:
```
$ docker build -f ./Dockerfile -t desafio-devops:latest ./

```

To run the docker image:
```
$ docker run -it \
    -p 8000:8000 \
    desafio-devops:latest
```