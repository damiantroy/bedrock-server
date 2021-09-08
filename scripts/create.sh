#!/usr/bin/env bash

IMAGE_NAME=bedrock-server:latest

CONTAINER_RUNTIME=$(command -v podman 2> /dev/null || echo docker)

if [ -z "$MINECRAFT_NAME" ]; then
    echo "Error: MINECRAFT_NAME variable not set!"
fi
BASE_DIR="/etc/minecraft/$MINECRAFT_NAME"
PORT=$(grep -oP "^server-port=\K\d+" "/etc/minecraft/${MINECRAFT_NAME}/config/server.properties")

sudo $CONTAINER_RUNTIME run -d \
    --name="minecraft-${MINECRAFT_NAME}" \
    -v "${BASE_DIR}/config:/bedrock-server/config:Z" \
    -v "${BASE_DIR}/worlds:/bedrock-server/worlds:Z" \
    -p $PORT:$PORT/udp \
    $IMAGE_NAME

