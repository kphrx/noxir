import Config

information =
  Keyword.filter(
    [
      name: System.get_env("RELAY_NAME"),
      description: System.get_env("RELAY_DESC"),
      pubkey: System.get_env("OWNER_PUBKEY"),
      contact: System.get_env("OWNER_CONTACT")
    ],
    fn {_, v} -> !is_nil(v) end
  )

config :noxir, :information, information
