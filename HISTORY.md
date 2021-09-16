## v0.1.0,


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