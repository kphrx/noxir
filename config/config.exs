import Config

config :noxir, :information,
  name: "Noxir",
  description: "The Nostr relay implemented in Elixir.",
  pubkey: nil,
  contact: nil,
  software: "https://github.com/kphrx/noxir"

import_config "#{config_env()}.exs"
