FROM ubuntu:focal
ARG BDS_Version=latest

ENV VERSION=$BDS_Version
ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y unzip curl && \
    rm -rf /var/lib/apt/lists/*
COPY test.sh /usr/local/bin/

# Download and extract the bedrock server
RUN if [ "$VERSION" = "latest" ] ; then \
        LATEST_VERSION=$( \
            curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.${RANDOM}.116 Safari/537.36" -H "Accept-Language: en" https://www.minecraft.net/en-us/download/server/bedrock 2>&1 | \
            grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^""]*' | \
            sed 's#.*/bedrock-server-##' | sed 's/.zip//') && \
        export VERSION=$LATEST_VERSION && \
        echo "Setting VERSION to $LATEST_VERSION"; \
    else \
        echo "Using VERSION of $VERSION"; \
    fi && \
    curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.${RANDOM}.116 Safari/537.36" https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${VERSION}.zip --output /tmp/bedrock-server.zip && \
    ls -la /tmp/bedrock-server.zip && \
    unzip /tmp/bedrock-server.zip -d /bedrock-server && \
    rm -f /tmp/bedrock-server.zip

# Move config to exposable volume
RUN mkdir -p /bedrock-server/config && \
    mv /bedrock-server/server.properties /bedrock-server/config/ && \
    mv /bedrock-server/permissions.json /bedrock-server/config/ && \
    ln -s /bedrock-server/config/server.properties /bedrock-server/server.properties && \
    ln -s /bedrock-server/config/permissions.json /bedrock-server/permissions.json

EXPOSE 19132/udp

VOLUME /bedrock-server/worlds /bedrock-server/config

WORKDIR /bedrock-server
ENV LD_LIBRARY_PATH=.
CMD ./bedrock_server
