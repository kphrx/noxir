defmodule Noxir.Plug.Connect do
  @moduledoc """
  A Plug to convert `CONNECT` requests to `GET` requests.
  """

  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init([]), do: []

  @impl Plug
  def call(%Conn{method: "CONNECT"} = conn, _), do: %{conn | method: "GET"}
  def call(conn, []), do: conn
end
