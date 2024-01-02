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

### Docker

- `edge`: this tag created from `master` branch.
- `latest`: this tag created from latest release version.

```console
$ docker run -it --rm ghcr.io/kphrx/noxir:edge
```
