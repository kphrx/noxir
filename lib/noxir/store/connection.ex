defmodule Noxir.Store.Connection do
  @moduledoc false

  use Memento.Table,
    attributes: [:pid, :subscriptions]

  alias Memento.Query

  @spec open(pid()) :: Memento.Table.record() | no_return()
  def open(pid) do
    Query.write(%__MODULE__{
      pid: pid,
      subscriptions: []
    })
  end

  @spec disconnect(pid()) :: :ok
  def disconnect(pid) do
    Query.delete(__MODULE__, pid)
  end

  @spec subscribe(pid(), binary(), [map()]) :: Memento.Table.record() | no_return()
  def subscribe(pid, sub_id, filters) do
    __MODULE__
    |> Query.read(pid)
    |> Map.replace_lazy(:subscriptions, fn subs ->
      List.keystore(subs, sub_id, 0, {sub_id, filters})
    end)
    |> Query.write()
  end

  @spec close(pid(), binary()) :: Memento.Table.record() | no_return()
  def close(pid, sub_id) do
    __MODULE__
    |> Query.read(pid)
    |> Map.replace_lazy(:subscriptions, fn subs ->
      List.keydelete(subs, sub_id, 0)
    end)
    |> Query.write()
  end

  @spec all :: [Memento.Table.record()]
  def all do
    Query.all(__MODULE__)
  end

  @spec get_subscriptions(pid()) :: [{binary(), [map()]}]
  def get_subscriptions(pid) do
    __MODULE__
    |> Query.read(pid)
    |> Map.get(:subscriptions)
  end
end
