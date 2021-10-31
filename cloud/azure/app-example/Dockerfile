# pull official base image
FROM python:3.9.6-alpine

# set work directory
WORKDIR /usr/src

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install dependencies
RUN pip install --upgrade pip

COPY ./app/requirements.txt ./app/
RUN cd app && pip install -r requirements.txt

# copy entrypoint.sh
COPY ./entrypoint.sh .
RUN sed -i 's/\r$//g' /usr/src/entrypoint.sh
RUN chmod +x /usr/src/entrypoint.sh

# copy project
COPY . .

EXPOSE 8000

# run entrypoint.sh
ENTRYPOINT ["/usr/src/entrypoint.sh"]