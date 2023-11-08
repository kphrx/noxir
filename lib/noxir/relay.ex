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
      Connection.start(pid)
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

  def handle_info(msg, state) do
    {:push, {:text, msg}, state}
  end

  @impl WebSock
  def terminate(_, state) do
    Memento.transaction!(fn ->
      Connection.disconnect(self())
    end)

    {:ok, state}
  end

  defp handle_nostr_event(event) do
    case Memento.transaction(fn ->
           Event.create(event)
         end) do
      {:ok, _} ->
        {true, ""}

      {:error, reason} ->
        Logger.debug(reason)
        {false, "Something went wrong"}
    end
  end

  defp resp_nostr_ok({accepted, msg}, id, opcode, state) do
    {:push, {opcode, Jason.encode!(["OK", id, accepted, msg])}, state}
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
        ["EVENT", sub_id, Store.to_map(event)]
      end)
      |> Enum.reverse()

    msgs =
      [["EOSE", sub_id] | evt_msgs]
      |> Enum.map(fn msg -> {opcode, Jason.encode!(msg)} end)
      |> Enum.reverse()

    {:push, msgs, state}
  end

  defp handle_nostr_close(sub_id) do
    Memento.transaction!(fn ->
      Connection.close(self(), sub_id)
    end)
  end

  defp resp_nostr_notice(msg, opcode, state) do
    {:push, {opcode, Jason.encode!(["NOTICE", msg])}, state}
  end
end
