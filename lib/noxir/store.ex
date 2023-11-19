defmodule Noxir.Store do
  @moduledoc """
  Utility for `Memento.Table`.
  """

  use GenServer

  alias Memento.Table
  alias Noxir.Store.Connection
  alias Noxir.Store.Event
  alias Event.TagIndex

  @tables [
    Connection,
    Event,
    TagIndex
  ]

  @spec start_link([GenServer.option()]) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: NoxirStore)
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

  def handle_info({:nodedown, _}, state) do
    Memento.add_nodes(Node.list())
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:create_event, event}, {from, _}, state) do
    result =
      case Memento.transaction(fn ->
             Event.create(event)
           end) do
        {:ok, ev} ->
          GenServer.cast(NoxirStore, {:create_event, ev, from})
          {:ok, ev}

        e ->
          e
      end

    {:reply, result, state}
  end

  def handle_call({:replace_event, event, type}, {from, _}, state) do
    result =
      case Memento.transaction(fn ->
             Event.create(event)
           end) do
        {:ok, ev} ->
          GenServer.cast(NoxirStore, {:create_event, ev, from})
          GenServer.cast(NoxirStore, {:replace_event, ev, type})
          {:ok, ev}

        e ->
          e
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_cast({:create_event, event, from}, state) do
    fn ->
      Connection.all()
    end
    |> Memento.transaction!()
    |> Enum.map(fn %Connection{pid: pid} -> pid end)
    |> Enum.filter(fn pid ->
      pid != from
    end)
    |> Enum.each(fn pid ->
      Process.send(pid, {:create_event, event}, [])
    end)

    {:noreply, state}
  end

  def handle_cast({:replace_event, %Event{pubkey: pkey, kind: kind}, :replaceable}, state) do
    Memento.transaction!(fn ->
      Event.delete_old({pkey, kind})
    end)

    {:noreply, state}
  end

  def handle_cast(
        {:replace_event, %Event{pubkey: pkey, kind: kind, tags: tags}, :parameterized},
        state
      ) do
    dtags =
      tags
      |> Enum.filter(fn
        ["d", _ | _] -> true
        _ -> false
      end)
      |> Enum.map(fn [_, tag | _] -> tag end)

    Memento.transaction!(fn ->
      Event.delete_old({pkey, kind, dtags})
    end)

    {:noreply, state}
  end

  @spec create_event(Event.t() | map()) :: {:ok, Table.record()} | {:error, any()}
  def create_event(event) do
    GenServer.call(NoxirStore, {:create_event, event}, :infinity)
  end

  @spec replace_event(Event.t() | map(), type :: :replaceable | :parameterized) ::
          {:ok, Table.record()} | {:error, any()}
  def replace_event(event, type \\ :replaceable) do
    GenServer.call(NoxirStore, {:replace_event, event, type}, :infinity)
  end

  @spec change_to_existing_atom_key(map()) :: map()
  def change_to_existing_atom_key(map) do
    for {key, val} <- map, into: %{} do
      key =
        try do
          String.to_existing_atom(key)
        rescue
          _ -> key
        end

      {key, val}
    end
  end

  @spec to_map(struct()) :: map()
  def to_map(%{__meta__: Table} = map) do
    map
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
