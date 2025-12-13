#!/usr/bin/env bash
set -e

CONFIG_FILE="${HOME}/.config/bedrock-server/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo "Config file $CONFIG_FILE not found"
    exit 1
fi

STORAGE_DIR=${HOME}/.local/share/bedrock-server
PREVIOUS_VERSION_FILE=${STORAGE_DIR}/last-version.txt
CONTAINER_RUNTIME=$(command -v podman 2>/dev/null || echo docker)

mkdir -p "$STORAGE_DIR"

if [[ -f "$PREVIOUS_VERSION_FILE" ]]; then
    PREVIOUS_VERSION=$(<"$PREVIOUS_VERSION_FILE")
else
    PREVIOUS_VERSION="-"
fi

INFO=$(curl -s https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json)
read -r LATEST_VERSION DOWNLOAD_URL <<<"$(
  jq -r '
    .release
    | to_entries
    | sort_by(.key | split(".") | map(tonumber))     # natural sem-ver sort
    | last                                           # newest entry
    | "\(.key) \(.value.linux.url)"
  ' <<<"$INFO"
)"

if [[ "$PREVIOUS_VERSION" != "$LATEST_VERSION" ]]; then
    USERNAME=${USERNAME:-$USER}
    REPO_NAME=${REPO_NAME:-docker.io}
    IMAGE_NAME=${IMAGE_NAME:-$USERNAME/bedrock-server}
    SECRET=${SECRET:-$USERNAME}

    OUTPUT=$(
        {
            SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
            PARENT_DIR=$(dirname "$SCRIPT_DIR")
            cd "$PARENT_DIR" || exit 1

            $CONTAINER_RUNTIME login --secret "$SECRET" -u "$USERNAME" "$REPO_NAME"
            make build-nc
            make test

            MAJOR_MINOR="$(cut -d. -f1,2 <<<"$LATEST_VERSION" | tr -d '[:space:]')"
            $CONTAINER_RUNTIME tag "$IMAGE_NAME:latest" "$REPO_NAME/$IMAGE_NAME:$LATEST_VERSION"
            $CONTAINER_RUNTIME tag "$IMAGE_NAME:latest" "$REPO_NAME/$IMAGE_NAME:$MAJOR_MINOR"
            $CONTAINER_RUNTIME push "$REPO_NAME/$IMAGE_NAME:$LATEST_VERSION"
            $CONTAINER_RUNTIME push "$REPO_NAME/$IMAGE_NAME:$MAJOR_MINOR"
            $CONTAINER_RUNTIME push "$REPO_NAME/$IMAGE_NAME:latest"
        } 2>&1
    )

    if [ $? -eq 0 ]; then
        echo "$LATEST_VERSION" > "$PREVIOUS_VERSION_FILE"
    fi

    {
        echo "To: $EMAIL_TO"
        echo "From: $EMAIL_FROM"
        echo "Subject: Bedrock Version: $PREVIOUS_VERSION -> $LATEST_VERSION"
        echo
        echo "The Bedrock server has upgraded from version $PREVIOUS_VERSION to $LATEST_VERSION."
        echo "This can be downloaded: from https://www.minecraft.net/en-us/download/server/bedrock"
        echo "Or directly from: $DOWNLOAD_URL"
        echo
        echo "-- Build Log --"
        echo "$OUTPUT"
    } | /usr/sbin/sendmail -t
fi
