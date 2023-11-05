defmodule Noxir.Relay do
  @behaviour WebSock

  def init(options) do
    Process.send_after(self(), :ping, 30_000)

    {:ok, options}
  end

  def handle_in({data, opcode: opcode}, state) do
    case Jason.decode(data) do
      {:ok, ["EVENT", %{"id" => id} = event]} ->
        handle_nostr_event(event)
        |> resp_nostr_ok(id, opcode, state)

      {:ok, ["REQ", subscription_id | filters]} ->
        handle_nostr_req(subscription_id, filters)
        |> resp_nostr_event_and_eose(opcode, state)

      {:ok, ["CLOSE", subscription_id]} ->
        handle_nostr_close(subscription_id)
        resp_nostr_notice("closed `#{subscription_id}`", opcode, state)

      _ ->
        resp_nostr_notice("incorrect event payload", opcode, state)
    end
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, 50_000)
    {:push, {:ping, ""}, state}
  end

  def handle_info(msg, state) do
    {:push, {:text, msg}, state}
  end

  defp handle_nostr_event(_event) do
    {true, ""}
  end

  defp resp_nostr_ok({accepted, msg}, id, opcode, state) do
    {:push, {opcode, Jason.encode!(["OK", id, accepted, msg])}, state}
  end

  defp handle_nostr_req(sub_id, _filters) do
    {sub_id, []}
  end

  defp resp_nostr_event_and_eose({sub_id, events}, opcode, state) do
    evt_msgs =
      events
      |> Enum.map(fn ev -> ["EVENT", sub_id, ev] end)
      |> Enum.reverse()

    msgs =
      [["EOSE", sub_id] | evt_msgs]
      |> Enum.map(fn msg -> {opcode, Jason.encode!(msg)} end)
      |> Enum.reverse()

    {:push, msgs, state}
  end

  defp handle_nostr_close(_sub_id), do: nil

  defp resp_nostr_notice(msg, opcode, state) do
    {:push, {opcode, Jason.encode!(["NOTICE", msg])}, state}
  end
end
