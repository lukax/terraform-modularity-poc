# v0.1.5

## Setting up monitoring

TODO...

# v0.1.4

## Building a CI/CD with Azure Pipelines 

* Connect Azure DevOps to the GitHub repository
* Configure the pipeline to build app Docker-compose image
* Set a branch trigger master/develop for either production/QA following the Git Flow branching model
* Select Azure subscription and container registry
* Set $(AZURE_SUBSCRIPTION) and $(AZURE_CONTAINER_REGISTRY) environment [variables for the pipeline](https://docs.microsoft.com/pt-br/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch)
* Save the pipeline YAML file and run

# v0.1.3

## Tagging images and deploying to production

Tag the docker image:
```
$ docker tag desafio-devops:latest ldconsulting.azurecr.io/desafio-devops:latest
```

Push the docker image to Azure Container Registry:
```
$ docker push ldconsulting.azurecr.io/desafio-devops:latest
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