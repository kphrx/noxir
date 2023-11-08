defmodule Noxir.Store do
  @moduledoc """
  Utility for `Memento.Table`.
  """

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

  @spec to_map(__MODULE__.t()) :: map()
  def to_map(%__MODULE__{} = event) do
    event
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
