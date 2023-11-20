defmodule Noxir.Store.Event do
  @moduledoc false

  use Memento.Table,
    attributes: [:id, :pubkey, :created_at, :kind, :tags, :content, :sig],
    index: [:pubkey, :kind, :created_at]

  alias __MODULE__.TagIndex
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
    TagIndex.add_event(event)
    Query.write(event)
  end

  def create(event_map) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(event_map))
    |> __MODULE__.create()
  end

  @spec delete(__MODULE__.t() | map()) :: Table.record() | no_return()
  def delete(%__MODULE__{} = event) do
    TagIndex.remove_event(event)
    Query.delete_record(event)
  end

  def delete(event_map) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(event_map))
    |> __MODULE__.delete()
  end

  @spec delete_old(pubkey(), kind()) :: :ok
  def delete_old(pkey, kind) do
    __MODULE__
    |> Query.select([
      {:==, :pubkey, pkey},
      {:===, :kind, kind}
    ])
    |> delete_old_record()
  end

  @spec delete_old(pubkey(), kind(), [binary()]) :: :ok
  def delete_old(pkey, kind, params) do
    query =
      Filter
      |> struct(%{"#d": params})
      |> Filter.tag_queries([
        {:==, :pubkey, pkey},
        {:===, :kind, kind}
      ])

    __MODULE__
    |> Query.select(query)
    |> delete_old_record()
  end

  defp delete_old_record(record) do
    [_ | old] =
      Enum.sort(record, fn %__MODULE__{id: lid, created_at: lt},
                           %__MODULE__{id: rid, created_at: rt} ->
        cond do
          lt < rt -> true
          lt == rt and lid >= rid -> true
          true -> false
        end
      end)

    Enum.each(old, &delete/1)
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

    case Filter.tag_queries(filter) do
      {:ok, tag_queries} ->
        {query, opts} = Filter.to_mnesia_query(filter, tag_queries)
        Query.select(__MODULE__, query, opts)

      {:error, :not_found} ->
        []
    end
  end
end
