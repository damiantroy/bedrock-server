# ---- Build image -----------------------------------------------------------
FROM ubuntu:22.04
ARG BDS_VERSION=latest

ENV VERSION="$BDS_VERSION"
ENV DEBIAN_FRONTEND=noninteractive

# Core utilities + jq for JSON parsing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl unzip jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY test.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/test.sh

# ---------------------------------------------------------------------------
# Download & unpack Bedrock Dedicated Server
# ---------------------------------------------------------------------------
RUN bash -euxo pipefail -c '\
  JSON_URL="https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json" && \
  if [ "$VERSION" = "latest" ]; then \
    echo "🔎  Detecting latest Bedrock server version…" && \
    LATEST_URL=$(curl -s "$JSON_URL" | jq -r ".release | to_entries | sort_by(.key | split(\".\") | map(tonumber)) | last.value.linux.url") && \
    VERSION=$(basename "$LATEST_URL" | sed -e "s/bedrock-server-//" -e "s/\.zip$//") && \
    DOWNLOAD_URL="$LATEST_URL" && \
    echo "➡️   Latest version: $VERSION" ; \
  else \
    DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${VERSION}.zip" && \
    echo "➡️   Using user-supplied version: $VERSION" ; \
  fi && \
  curl -4 --http1.1 -A "Mozilla/5.0" -fsSL \
     --retry 3 --retry-delay 3 \
     "$DOWNLOAD_URL" -o /tmp/bedrock-server.zip && \
  unzip -q /tmp/bedrock-server.zip -d /bedrock-server && \
  rm /tmp/bedrock-server.zip'

# Move mutable config out to a volume
RUN mkdir -p /bedrock-server/config && \
    mv /bedrock-server/server.properties /bedrock-server/config/server.properties && \
    mv /bedrock-server/permissions.json /bedrock-server/config/permissions.json && \
    ln -sf config/server.properties /bedrock-server/server.properties && \
    ln -sf config/permissions.json /bedrock-server/permissions.json

EXPOSE 19132/udp
VOLUME /bedrock-server/worlds /bedrock-server/config

WORKDIR /bedrock-server
ENV LD_LIBRARY_PATH=.
CMD ["./bedrock_server"]

