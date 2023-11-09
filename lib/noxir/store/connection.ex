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
    conn =
      __MODULE__
      |> Query.read(pid)
      |> Map.replace_lazy(:subscriptions, fn subs ->
        List.keystore(subs, sub_id, 0, {sub_id, filters})
      end)

    Query.delete(__MODULE__, pid)
    Query.write(conn)
  end

  @spec close(pid(), binary()) :: Memento.Table.record() | no_return()
  def close(pid, sub_id) do
    conn =
      __MODULE__
      |> Query.read(pid)
      |> Map.replace_lazy(:subscriptions, fn subs ->
        List.keydelete(subs, sub_id, 0)
      end)

    Query.delete(__MODULE__, pid)
    Query.write(conn)
  end
end
