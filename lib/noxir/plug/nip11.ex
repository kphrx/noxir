defmodule Noxir.Plug.NIP11 do
  @moduledoc """
  A Plug to return Relay Information Document in NIP-11.
  """

  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init([]), do: []

  @impl Plug
  def call(conn, []) do
    case Conn.get_req_header(conn, "accept") do
      ["application/nostr+json" | _] ->
        information = Application.fetch_env!(:noxir, :information)

        conn
        |> Conn.put_resp_content_type("application/nostr+json")
        |> Conn.send_resp(
          200,
          Jason.encode!(%{
            name: Keyword.get(information, :name, ""),
            description: Keyword.get(information, :description, ""),
            pubkey: Keyword.get(information, :pubkey, ""),
            contact: Keyword.get(information, :contact, ""),
            supported_nips: [1, 11],
            software: Keyword.get(information, :software, ""),
            version: "v" <> to_string(Application.spec(:noxir, :vsn))
          })
        )
        |> Conn.halt()

      _ ->
        conn
    end
  end
end
