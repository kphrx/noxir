defmodule Noxir.Relay do
  @behaviour WebSock

  def init(options) do
    {:ok, options}
  end

  def handle_in({data, opcode: opcode}, state) do
    {:push, {opcode, data}, state}
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end
end
