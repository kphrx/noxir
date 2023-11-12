defmodule Noxir.Relay do
  @moduledoc """
  Nostr Relay message handler.
  """

  @behaviour WebSock

  alias Noxir.Store
  alias Noxir.Store.Connection
  alias Noxir.Store.Event

  require Logger

  @impl WebSock
  def init(options) do
    pid = self()

    Memento.transaction!(fn ->
      Connection.open(pid)
    end)

    Process.send_after(pid, :ping, 30_000)

    {:ok, options}
  end

  @impl WebSock
  def handle_in({data, opcode: opcode}, state) do
    case Jason.decode(data) do
      {:ok, ["EVENT", %{"id" => id} = event]} ->
        event
        |> handle_nostr_event()
        |> resp_nostr_ok(id, opcode, state)

      {:ok, ["REQ", subscription_id | filters]} ->
        subscription_id
        |> handle_nostr_req(filters)
        |> resp_nostr_event_and_eose(opcode, state)

      {:ok, ["CLOSE", subscription_id]} ->
        handle_nostr_close(subscription_id)
        resp_nostr_notice("Closed sub_id: `#{subscription_id}`", opcode, state)

      _ ->
        resp_nostr_notice("Invalid message", opcode, state)
    end
  end

  @impl WebSock
  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, 50_000)

    {:push, {:ping, ""}, state}
  end

  def handle_info({:event_create, %Event{} = event}, state) do
    event_map = Store.to_map(event)

    msgs =
      fn ->
        Connection.get_subscriptions(self())
      end
      |> Memento.transaction!()
      |> Enum.filter(fn {_, filters} ->
        Event.match(event, filters)
      end)
      |> Enum.map(fn {sub_id, _} ->
        msg =
          event_map
          |> resp_nostr_event_msg(sub_id)
          |> Jason.encode!()

        {:text, msg}
      end)

    {:push, msgs, state}
  end

  @impl WebSock
  def terminate(_, state) do
    Memento.transaction!(fn ->
      Connection.disconnect(self())
    end)

    {:ok, state}
  end

  defp handle_nostr_event(event) do
    case Store.event_create(event) do
      {:ok, _} ->
        {:ok, ""}

      {:error, reason} ->
        Logger.debug(reason)
        {:error, "Something went wrong"}
    end
  end

  defp resp_nostr_ok(res, id, opcode, state) do
    {:push, {opcode, resp_nostr_ok_msg(res, id)}, state}
  end

  defp handle_nostr_req(sub_id, filters) do
    Memento.transaction!(fn ->
      Connection.subscribe(self(), sub_id, filters)
    end)

    case Memento.transaction(fn ->
           Event.req(filters)
         end) do
      {:ok, data} ->
        {sub_id, data}

      {:error, reason} ->
        Logger.debug(reason)
        {sub_id, []}
    end
  end

  defp resp_nostr_event_and_eose({sub_id, events}, opcode, state) do
    evt_msgs =
      events
      |> Enum.map(fn event ->
        event
        |> Store.to_map()
        |> resp_nostr_event_msg(sub_id)
      end)
      |> Enum.reverse()

    msgs =
      [resp_nostr_eose_msg(sub_id) | evt_msgs]
      |> Enum.map(fn msg -> {opcode, msg} end)
      |> Enum.reverse()

    {:push, msgs, state}
  end

  defp handle_nostr_close(sub_id) do
    Memento.transaction!(fn ->
      Connection.close(self(), sub_id)
    end)
  end

  defp resp_nostr_notice(msg, opcode, state) do
    {:push, {opcode, resp_nostr_event_msg(msg)}, state}
  end

  defp resp_nostr_event_msg(event, sub_id), do: Jason.encode!(["EVENT", sub_id, event])

  defp resp_nostr_ok_msg({:ok, msg}, id), do: Jason.encode!(["OK", id, true, msg])
  defp resp_nostr_ok_msg({:error, msg}, id), do: Jason.encode!(["OK", id, false, msg])

  defp resp_nostr_eose_msg(sub_id), do: Jason.encode!(["EOSE", sub_id])

  defp resp_nostr_event_msg(msg), do: Jason.encode!(["NOTICE", msg])
end
