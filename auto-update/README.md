# Podman Auto Updates


1. Set  your config variables:
    ```shell
    export MC_WORLD_NAME=my_world
    export MC_IMAGE_NAME=docker.io/damiantroy/bedrock-server:latest
    export MC_BASE_DIR="/etc/minecraft/$MC_WORLD_NAME"
    export MC_PORT=19132
    export MC_CONT_NAME="minecraft-${MC_WORLD_NAME}"
    ```
1. Install your `systemd` file:
    ```shell
    envsubst < auto-update/container-template.service | sudo tee "/etc/systemd/system/container-${MC_CONT_NAME}.service"
    sudo systemctl daemon-reload
    ```
1. Enable and start your container:
    ```shell
    sudo systemctl enable --now "container-${MC_CONT_NAME}"
    ```
1. (Optional) Enable daily auto-updates:
    ```shell
    sudo systemctl enable --now podman-auto-update.timer
    ```

Credit to [this post](https://blog.while-true-do.io/podman-auto-updates/),
where you'll find more details on Podman auto-updates.
