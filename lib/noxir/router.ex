defmodule Noxir.Router do
  use Plug.Router

  plug Plug.Logger

  plug Plug.Head
  plug :connect

  plug :websocket

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, """
    Please use a Nostr client to connect.
    """)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  def connect(%Plug.Conn{method: "CONNECT"} = conn, _), do: %{conn | method: "GET"}
  def connect(conn, _), do: conn

  def websocket(conn, _) do
    case WebSockAdapter.UpgradeValidation.validate_upgrade(conn) do
      :ok ->
        conn |> WebSockAdapter.upgrade(Noxir.Relay, [], timeout: 60_000) |> halt()

      _ ->
        conn
    end
  end
end
