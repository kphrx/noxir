defmodule Noxir.Store.Event do
  @moduledoc false

  use Memento.Table,
    attributes: [:id, :pubkey, :created_at, :kind, :tags, :content, :sig],
    index: [:pubkey, :kind, :created_at]

  alias Memento.Query
  alias Memento.Table
  alias Noxir.Store
  alias Store.Filter

  @type t :: %__MODULE__{
          id: binary(),
          pubkey: binary(),
          created_at: integer(),
          kind: integer(),
          tags: [[binary()]],
          content: binary(),
          sig: binary()
        }

  @spec create(__MODULE__.t()) :: Table.record() | no_return()
  def create(%__MODULE__{} = event) do
    Query.write(event)
  end

  @spec create(map()) :: Table.record() | no_return()
  def create(event_map) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(event_map))
    |> __MODULE__.create()
  end

  @spec req(map()) :: [Table.record()]
  def req(filters) do
    __MODULE__
    |> Query.all()
    |> Enum.filter(&Filter.match?(filters, &1))
  end
end
