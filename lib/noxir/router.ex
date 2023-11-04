defmodule Noxir.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  match "/", via: [:get, :head, :connect] do
    case WebSockAdapter.UpgradeValidation.validate_upgrade(conn) do
      :ok ->
        conn |> WebSockAdapter.upgrade(Noxir.Relay, [], timeout: 60_000) |> halt()

      _ ->
        conn
        |> send_resp(200, """
        Please use a Nostr client to connect.
        """)
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
