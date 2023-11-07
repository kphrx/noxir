defmodule Noxir.Relay do
  @moduledoc """
  Nostr Relay message handler.
  """

  @behaviour WebSock

  require Logger

  @impl WebSock
  def init(options) do
    Process.send_after(self(), :ping, 30_000)

    {:ok, options}
  end

  @impl WebSock
  def handle_in({data, opcode: opcode}, state) do
    case Jason.decode(data, keys: :atoms!) do
      {:ok, ["EVENT", %{id: id} = event]} ->
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

  defp handle_nostr_event(event) do
    case Memento.transaction(fn ->
           %Noxir.Event{}
           |> struct(event)
           |> Memento.Query.write()
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

  defp handle_nostr_req(sub_id, _) do
    case Memento.transaction(fn ->
           Memento.Query.all(Noxir.Event)
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
        ev =
          event
          |> Map.from_struct()
          |> Map.delete(:__meta__)

        ["EVENT", sub_id, ev]
      end)
      |> Enum.reverse()

    msgs =
      [["EOSE", sub_id] | evt_msgs]
      |> Enum.map(fn msg -> {opcode, Jason.encode!(msg)} end)
      |> Enum.reverse()

    {:push, msgs, state}
  end

  defp handle_nostr_close(_), do: nil

  defp resp_nostr_notice(msg, opcode, state) do
    {:push, {opcode, Jason.encode!(["NOTICE", msg])}, state}
  end
end
