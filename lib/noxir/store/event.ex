defmodule Noxir.Store.Event do
  @moduledoc false

  use Memento.Table,
    attributes: [:id, :pubkey, :created_at, :kind, :tags, :content, :sig],
    index: [:pubkey, :kind, :created_at]

  alias Memento.Query
  alias Memento.Table
  alias Noxir.Store
  alias Store.Filter

  @type id :: binary()
  @type pubkey :: binary()
  @type created_at :: integer()
  @type kind :: integer()
  @type tag :: [binary()]
  @type tags() :: [tag()]
  @type content :: binary()
  @type sig :: binary()

  @type t :: %__MODULE__{
          id: id(),
          pubkey: pubkey(),
          created_at: created_at(),
          kind: kind(),
          tags: tags(),
          content: content(),
          sig: sig()
        }

  @spec create(__MODULE__.t() | map()) :: Table.record() | no_return()
  def create(%__MODULE__{} = event) do
    Query.write(event)
  end

  def create(event_map) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(event_map))
    |> __MODULE__.create()
  end

  @spec req([map()] | map()) :: [Table.record()] | {:error, any()}
  def req([]), do: {:error, "need one or more filters"}

  def req(filters) when is_list(filters) do
    filters
    |> Enum.map(&req/1)
    |> List.flatten()
    |> Enum.uniq_by(fn %__MODULE__{id: id} -> id end)
  end

  def req(filter) do
    filter = Filter.from_map(filter)
    {query, opts} = Filter.to_mnesia_query(filter)

    __MODULE__
    |> Query.select(query, opts)
    |> Enum.filter(&Filter.match_tags?(filter, &1))
  end
end
