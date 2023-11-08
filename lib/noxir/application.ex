defmodule Noxir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_, _) do
    children = [
      {Noxir.Store, []},
      {Bandit, scheme: :http, plug: Noxir.Router, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noxir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
