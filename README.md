# Minecraft Bedrock Server
Run a bedrock server in a Docker container.

## Introduction
This Docker image will download the Bedrock Server app and set it up, along with its dependencies.

## Usage
### New installation
1. Prepare the persistent volumes:
    1. Create a volume for the configuration:<br/>
        `docker volume create --name "bedrock-config"`
    1. Create a volume for the worlds:<br/>
        `docker volume create --name "bedrock-worlds"`
1. Create the Docker container:
    ```bash
    docker create --name=minecraft -it\
        -v "bedrock-config:/bedrock-server/config"\
        -v "bedrock-worlds:/bedrock-server/worlds"\
        -p 19132:19132/udp\
        --restart=unless-stopped\
        damiantroy/bedrock-server
    ```
1. Prepare the config files
    1. Either start the server once and stop it
    1. or copy the files from the original archives
1. Configure the default files in the `config` volume:
    1. Configure the `server.properties` to your likings.
    1. Configure the `whitelist.json` in case you have set `white-list=true` in the above step. Note: The `xuid` is optional and will automatically be added as soon as a matching player connects. Here's an example of a `whitelist.json` file:
        ```json
        [
            {
                "ignoresPlayerLimit": false,
                "name": "MyPlayer"
            },
            {
                "ignoresPlayerLimit": false,
                "name": "AnotherPlayer",
                "xuid": "274817248"
            }
        ]
        ```
    3. Configure the `permissions.json` and add the operators. This file consists of a list of `permissions` and `xuid`s. The `permissions` can be `member`, `visitor` or `operator`. The `xuid` can be copied from the `whitelist.json` as soon as the user connected once. An example could look like:
        ```json
        [
            {
                "permission": "operator",
                "xuid": "274817248"
            }
        ]
        ```
4. Start the server:<br/>
    `docker start minecraft`

### Updating
1. Stop the server<br/>
    ```
    docker attach minecraft
    stop
    ```
2. Re-create the server with the new image and the same settings (either `manually` or with `portainer` or Synologys `clean`).<br/>
    NOTE: When updating from 1.7, you need to use the new installation guide and put your `worlds` and `config` files into the newly created volumes or use appropriate volume mappings when creating the container. You also need to rename `ops.json` to `permissions.json`.
3. Start the server
    `docker start minecraft`

## Commands
There are various commands that can be used in the console. To access the console, you need to attach to the container with the following command:
```
docker attach <container-id>
```
To leave the console without exiting the container, use `Ctrl`+`p` + `Ctrl`+`q`.

Here are the commands:

| Command syntax | Description |
| -------------- | ----------- |
| kick {`player name` or `xuid`} {`reason`} | Immediately kicks a player. The reason will be shown on the kicked players screen. |
| stop | Shuts down the server gracefully. |
| save {`hold` or `resume` or `query`} | Used to make atomic backups while the server is running. See the backup section for more information. |
| whitelist {`on` or `off` or `list` or `reload`} | `on` and `off` turns the whitelist on and off. Note that this does not change the value in the `server.properties` file!<br />`list` prints the current whitelist used by the server<br />`reload` makes the server reload the whitelist from the file.
| whitelist {`add` or `remove`} {`name`} | Adds or removes a player from the whitelist file. The name parameter should be the Xbox Gamertag of the player you want to add or remove. You don't need to specify a XUID here, it will be resolved the first time the player connects. |
| permission {`list` or `reload`} | `list` prints the current used permissions list.<br />`reload` makes the server reload the operator list from the permissions file. |
| op {`player name`} | Promote a player to `operator`. This will also persist in `permissions.json` if the player is authenticated to XBL. If `permissions.json` is missing it will be created. If the player is not connected to XBL, the player is promoted for the current server session and it will not be persisted on disk. Default server permission level will be assigned to the player after a server restart. |
| deop {`player name`} | Demote a player to `member`. This will also persist in `permissions.json` if the player is authenticated to XBL. If `permissions.json` is missing it will be created. |
| changesetting {`setting`} {`value`} | Changes a server setting without having to restart the server. Currently only two settings are supported to be changed, `allow-cheats` (`true` or `false`) and `difficulty` (0, `peaceful`, 1, `easy`, 2, `normal`, 3 or `hard`). They do not modify the value that's specified in `server.properties`. |

## Backups
The server supports taking backups of the world files while the server is running. It's not particularly friendly for taking manual backups, but works better when automated. The backup (from the servers perspective) consists of three commands:

| Command | Description |
| ------- | ----------- |
| save hold | This will ask the server to prepare for a backup. It’s asynchronous and will return immediately. |
| save query | After calling `save hold` you should call this command repeatedly to see if the preparation has finished. When it returns a success it will return a file list (with lengths for each file) of the files you need to copy. The server will not pause while this is happening, so some files can be modified while the backup is taking place. As long as you only copy the files in the given file list and truncate the copied files to the specified lengths, then the backup should be valid. |
| save resume | When you’re finished with copying the files you should call this to tell the server that it’s okay to remove old files again. |

## Podman on CentOS

### Initial Setup

```bash
sudo useradd minecraft
sudo mkdir -p /srv/minecraft
sudo chown -R minecraft:minecraft /srv/minecraft
sudo firewall-cmd --new-service-from-file firewalld/minecraft.xml --permanent
sudo firewall-cmd --add-service minecraft --permanent
sudo firewall-cmd --reload
```

### Per World Setup

Expand your port range to cover all worlds:

```bash
sudo vim /etc/firewalld/services/minecraft.xml
sudo firewall-cmd --reload
```

The next section will generate your per world config, so be sure to
inspect and customise the configuration files to your liking.

```bash
sudo su - minecraft

# Config
export MC_WORLD_NAME=MyWorld
export MC_PORT=19132
export MC_PORTV6=19133
export MC_XUID=1234567890
export MC_PLAYER=MyName
mkdir -p /srv/minecraft/${MC_WORLD_NAME}/{config,worlds}
envsubst < config/permissions.json > /srv/minecraft/${MC_WORLD_NAME}/config/permissions.json
envsubst < config/server.properties > /srv/minecraft/${MC_WORLD_NAME}/config/server.properties
envsubst < config/whitelist.json > /srv/minecraft/${MC_WORLD_NAME}/config/whitelist.json

# Systemd
mkdir -p .config/containers/systemd
envsubst < systemd/minecraft-template.container > ~/.config/containers/systemd/minecraft-${MC_WORLD_NAME}.container
systemctl --user daemon-reload
systemctl --user start minecraft-${MC_WORLD_NAME}
```

Once the world has started, you can configure your client to connect to
your server's IP, and the port you specified.

### Build

Be sure to change the image name to your own.

```bash
export REPO_NAME=docker.io
export IMAGE_NAME=damiantroy/bedrock-server
podman login "$REPO_NAME"
make build-nc
make test
make push
```

