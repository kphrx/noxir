defmodule Noxir.Store do
  @moduledoc """
  Utility for `Memento.Table`.
  """

  use GenServer

  alias Memento.Table
  alias Noxir.Store.Connection
  alias Noxir.Store.Event

  @tables [
    Connection,
    Event
  ]

  @spec start_link([GenServer.option()]) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(options) do
    :net_kernel.monitor_nodes(true)

    for table <- @tables do
      Table.create!(table)
    end

    :ok = Table.wait(@tables, :infinity)

    {:ok, options}
  end

  @impl GenServer
  def handle_info({:nodeup, _}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:nodedown, _}, state) do
    Memento.add_nodes(Node.list())
    {:noreply, state}
  end

  @spec change_to_existing_atom_key(map()) :: map()
  def change_to_existing_atom_key(map) do
    for {key, val} <- map, into: %{} do
      key =
        try do
          String.to_existing_atom(key)
        rescue
          ArgumentError -> key
        end

      {key, val}
    end
  end

  @spec to_map(struct()) :: map()
  def to_map(%{__meta__: Memento.Table} = map) do
    map
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
