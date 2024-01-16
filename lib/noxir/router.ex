defmodule Noxir.Router do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :noxir
  end

  use Plug.ErrorHandler

  plug(Plug.RewriteOn, [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto])
  plug(Plug.Logger)
  plug(CORSPlug)

  plug(Plug.Head)
  plug(Noxir.Plug.Connect)
  plug(Noxir.Plug.WebSocket, Noxir.Relay)
  plug(Noxir.Plug.NIP11)

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp_with_nip11(200, """
    Please use a Nostr client to connect.
    """)
  end

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp_with_nip11(404, "not found")
  end

  defp send_resp_with_nip11(conn, status, body) do
    case conn.private[:nip11] do
      true ->
        information =
          :noxir
          |> Application.fetch_env!(:information)
          |> Keyword.filter(fn {_, v} -> !is_nil(v) end)

        conn
        |> put_resp_content_type("application/nostr+json")
        |> send_resp(
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

      nil ->
        send_resp(conn, status, body)
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
