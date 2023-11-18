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
        Conn.put_private(conn, :nip11, true)

      _ ->
        conn
    end
  end
end
