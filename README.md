# Noxir

Nostr Relay in Elixir with Mnesia.

## Installation

### Build from source

1. Clone source code from git.
   ```console
   $ git clone https://github.com/kphrx/noxir
   ```

1. Build application.
   ```console
   $ mix deps.get --only prod
   Resolving Hex dependencies...
   $ MIX_ENV=prod mix compile
   Generated noxir app
   ```

1. Starting server on `http://localhost:4000`.
   ```console
   $ MIX_ENV=prod mix run --no-halt
   [info] Running Noxir.Router with Bandit 1.1.2 at 0.0.0.0:4000 (http)
   ```

### Docker Compose

1. Overwrite environment and docker image tag, and scale config to `docker.override.yml`.
   ```yml
   version: '3'

   services:
     app:
       environment:
         RELAY_NAME: "<relay info name>"
         RELAY_DESC: "<relay info description>"
         OWNER_PUBKEY: "<hex format public key>"
         OWNER_CONTACT: "<contact infomation uri. for example: mailto uri>"
       deploy:
         replicas: 3
   ```

1. Start container.
   ```console
   $ docker compose up -d
   [+] Running 3/3
    ✔ Container noxir-app-1  Started
    ✔ Container noxir-app-2  Started
    ✔ Container noxir-app-3  Started
   ```

### Docker

- `edge`: this tag created from `master` branch.
- `latest`: this tag created from latest release version.

```console
$ docker run -it --rm ghcr.io/kphrx/noxir:edge
```
