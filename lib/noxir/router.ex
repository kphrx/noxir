defmodule Noxir.Router do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :noxir
  end

  use Plug.ErrorHandler

  plug(Plug.RewriteOn, [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto])
  plug(Plug.Logger)

  plug(Plug.Head)
  plug(Noxir.Plug.Connect)
  plug(Noxir.Plug.WebSocket, Noxir.Relay)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, """
    Please use a Nostr client to connect.
    """)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
