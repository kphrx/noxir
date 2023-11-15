defmodule Noxir.Store.Event do
  @moduledoc false

  use Memento.Table,
    attributes: [:id, :pubkey, :created_at, :kind, :tags, :content, :sig],
    index: [:pubkey, :kind, :created_at]

  alias Memento.Query

  @type t :: %__MODULE__{
          id: binary(),
          pubkey: binary(),
          created_at: integer(),
          kind: integer(),
          tags: [[binary()]],
          content: binary(),
          sig: binary()
        }

  @spec create(__MODULE__.t()) :: Memento.Table.record() | no_return()
  def create(%__MODULE__{} = event) do
    Query.write(event)
  end

  @spec create(map()) :: Memento.Table.record() | no_return()
  def create(event_map) do
    __MODULE__
    |> struct(Noxir.Store.change_to_existing_atom_key(event_map))
    |> __MODULE__.create()
  end

  @spec req(map()) :: [Memento.Table.record()]
  def req(filters) do
    __MODULE__
    |> Query.all()
    |> Enum.filter(&filter_match?(&1, filters))
  end

  @spec filter_match?(__MODULE__.t(), filters :: map()) :: boolean()
  def filter_match?(
        %__MODULE__{id: id, pubkey: pkey, kind: kind, created_at: created_at, tags: tags},
        filters
      ) do
    Enum.any?(filters, fn filter ->
      with true <- match_ids?(filter, id),
           true <- match_authors?(filter, pkey),
           true <- match_kinds?(filter, kind),
           true <- match_range?(filter, created_at),
           true <- match_tags?(filter, tags, "e"),
           true <- match_tags?(filter, tags, "p") do
        true
      else
        _ -> false
      end
    end)
  end

  defp match_ids?(%{} = filter, id),
    do:
      filter
      |> Map.get("ids")
      |> match_ids?(id)

  defp match_ids?([_ | _] = ids, id), do: Enum.any?(ids, &(&1 == id))
  defp match_ids?([], _), do: true
  defp match_ids?(nil, _), do: true

  defp match_authors?(%{} = filter, pubkey),
    do:
      filter
      |> Map.get("authors")
      |> match_authors?(pubkey)

  defp match_authors?([_ | _] = authors, pubkey), do: Enum.any?(authors, &(&1 == pubkey))
  defp match_authors?([], _), do: true
  defp match_authors?(nil, _), do: true

  defp match_kinds?(%{} = filter, kind),
    do:
      filter
      |> Map.get("kinds")
      |> match_kinds?(kind)

  defp match_kinds?([_ | _] = kinds, kind), do: Enum.any?(kinds, &(&1 == kind))
  defp match_kinds?([], _), do: true
  defp match_kinds?(nil, _), do: true

  defp match_range?(%{} = filter, created_at),
    do: match_since?(filter, created_at) && match_until?(filter, created_at)

  defp match_since?(%{} = filter, created_at),
    do:
      filter
      |> Map.get("since")
      |> match_since?(created_at)

  defp match_since?(nil, _), do: true
  defp match_since?(since, created_at), do: since <= created_at

  defp match_until?(%{} = filter, created_at),
    do:
      filter
      |> Map.get("until")
      |> match_until?(created_at)

  defp match_until?(nil, _), do: true
  defp match_until?(until, created_at), do: created_at <= until

  defp match_tags?(%{} = filter, tags, letter) do
    tags =
      Enum.filter(tags, fn
        [^letter | _] -> true
        _ -> false
      end)

    filter
    |> Map.get("##{letter}")
    |> match_tags?(tags)
  end

  defp match_tags?([_ | _] = tags_filter, tags),
    do: Enum.any?(tags, fn tag -> Enum.any?(tags_filter, &(&1 == tag)) end)

  defp match_tags?([], _), do: true
  defp match_tags?(nil, _), do: true
end
