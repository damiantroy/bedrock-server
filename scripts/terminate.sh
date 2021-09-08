#!/usr/bin/env bash

IMAGE_NAME=bedrock-server:latest

CONTAINER_RUNTIME=$(command -v podman 2> /dev/null || echo docker)

if [ -z "$MINECRAFT_NAME" ]; then
    echo "Error: MINECRAFT_NAME variable not set!"
fi
CONTAINER_NAME="minecraft-${MINECRAFT_NAME}"

sudo $CONTAINER_RUNTIME stop "$CONTAINER_NAME"
sudo $CONTAINER_RUNTIME rm "$CONTAINER_NAME"

