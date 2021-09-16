#!/bin/ash

ls && cd ./app && gunicorn -b "0.0.0.0:8000" --log-level debug api:app

exec "$@"