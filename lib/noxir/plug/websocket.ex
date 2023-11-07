defmodule Noxir.Plug.WebSocket do
  @moduledoc """
  A Plug to upgrade WebSocket connection.
  """

  @behaviour Plug

  alias Plug.Conn
  alias WebSockAdapter.UpgradeValidation

  @impl Plug
  def init(module), do: module

  @impl Plug
  def call(conn, module) do
    case UpgradeValidation.validate_upgrade(conn) do
      :ok ->
        conn
        |> WebSockAdapter.upgrade(module, [], timeout: 60_000)
        |> Conn.halt()

      _ ->
        conn
    end
  end
end
