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

  @spec req([map()] | map()) :: {:ok, [__MODULE__.t()]} | {:error, any()}
  def req([]), do: {:error, "need one or more filters"}

  def req(filters) when is_list(filters) do
    filters
    |> Enum.map(&req/1)
    |> List.flatten()
    |> Enum.uniq_by(fn %__MODULE__{id: id} -> id end)
  end

  def req(filter) do
    {query, opts} = Filter.to_mnesia_query(filter)
    Query.select(__MODULE__, query, opts)
  end
end
