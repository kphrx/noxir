defmodule Noxir.Store.Filter do
  @moduledoc false

  use Noxir.Store.FilterMatch

  alias Noxir.Store
  alias Store.Event

  @type memento_query :: [tuple()]
  @type query_opts :: Memento.Query.options()
  @type query :: {memento_query(), query_opts()}

  @spec to_mnesia_query([__MODULE__.t() | map()] | __MODULE__.t() | map()) :: [query()] | query()
  def to_mnesia_query(filters) when is_list(filters),
    do: Enum.map(filters, &__MODULE__.to_mnesia_query/1)

  def to_mnesia_query(%__MODULE__{
        ids: ids,
        authors: authors,
        kinds: kinds,
        since: since,
        until: until,
        limit: limit
      }) do
    query =
      []
      |> id_query(ids)
      |> pubkey_query(authors)
      |> kind_query(kinds)
      |> since_query(since)
      |> until_query(until)

    {query,
     limit:
       if limit > 0 do
         limit
       else
         nil
       end}
  end

  def to_mnesia_query(filter) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(filter))
    |> __MODULE__.to_mnesia_query()
  end

  defp id_query(res, [id]), do: [{:==, :id, id} | res]

  defp id_query(res, [_ | _] = ids),
    do: [List.to_tuple([:or | Enum.map(ids, &{:==, :id, &1})]) | res]

  defp id_query(res, _), do: res

  defp pubkey_query(res, [author]), do: [{:==, :pubkey, author} | res]

  defp pubkey_query(res, [_ | _] = authors),
    do: [List.to_tuple([:or | Enum.map(authors, &{:==, :pubkey, &1})]) | res]

  defp pubkey_query(res, _), do: res

  defp kind_query(res, [kind]), do: [{:==, :kind, kind} | res]

  defp kind_query(res, [_ | _] = kinds),
    do: [List.to_tuple([:or | Enum.map(kinds, &{:==, :kind, &1})]) | res]

  defp kind_query(res, _), do: res

  defp since_query(res, nil), do: res
  defp since_query(res, since), do: [{:>=, :created_at, since} | res]

  defp until_query(res, nil), do: res
  defp until_query(res, until), do: [{:<=, :created_at, until} | res]

  @spec match?([__MODULE__.t() | map()] | __MODULE__.t() | map(), Event.t()) :: boolean()
  def match?([], _), do: true

  def match?(filters, event) when is_list(filters),
    do: Enum.any?(filters, &__MODULE__.match?(&1, event))

  def match?(%__MODULE__{} = filter, %Event{} = event) do
    match_fields?(filter, event) and
      match_range?(filter, event) and
      match_tags?(filter, event)
  end

  def match?(filter, event) do
    __MODULE__
    |> struct(Store.change_to_existing_atom_key(filter))
    |> __MODULE__.match?(event)
  end

  defp match_fields?(%__MODULE__{ids: ids, authors: authors, kinds: kinds}, %Event{
         id: id,
         pubkey: pkey,
         kind: kind
       }),
       do: match_ids?(ids, id) and match_authors?(authors, pkey) and match_kinds?(kinds, kind)

  defp match_range?(%__MODULE__{since: since, until: until}, %Event{created_at: created_at}),
    do: match_since?(since, created_at) and match_until?(until, created_at)

  defp match_since?(nil, _), do: true
  defp match_since?(since, created_at), do: since <= created_at

  defp match_until?(nil, _), do: true
  defp match_until?(until, created_at), do: created_at <= until

  defp match_tags?(%__MODULE__{} = filter, %Event{tags: tags}) do
    Enum.all?(@tag_filters, &match_tags?(&1, filter, tags))
  end
end
