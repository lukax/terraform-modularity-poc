# v0.2.0

* add `Terraform/webapp.tf` file
 
Steps to get Terraform working with Azure Cloud:
* [configure Azure Cloud shell with bash](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash)
* [configure Terraform state storage in Azure Cloud](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)

To setup state storage for Terraform in Azure Cloud:
```
$ ./Terraform/setup-azure-storage.sh
```
Terraform state is used to reconcile deployed resources with Terraform configurations. State allows Terraform to know what Azure resources to add, update, or delete.

* To initialize the configuration
``` 
$ terraform init 
```

* To run the configuration
``` 
$ terraform apply 
```

# v0.1.0


#### Highlights

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