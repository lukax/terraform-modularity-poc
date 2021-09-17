#!/bin/bash

APP_URL="${APP_URL:-localhost:8000}"

# matéria 1
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"first post!","content_id":1}'
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"ok, now I am gonna say something more useful","content_id":1}'
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I agree","content_id":1}'

# matéria 2
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I guess this is a good thing","content_id":2}'
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"charlie@example.com","comment":"Indeed, dear Bob, I believe so as well","content_id":2}'
curl -sv ${APP_URL}/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"eve@example.com","comment":"Nah, you both are wrong","content_id":2}'

# listagem matéria 1
curl -sv ${APP_URL}/api/comment/list/1

# listagem matéria 2
curl -sv ${APP_URL}/api/comment/list/2