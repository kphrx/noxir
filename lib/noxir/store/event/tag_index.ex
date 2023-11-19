defmodule Noxir.Store.Event.TagIndex do
  @moduledoc false

  use Memento.Table,
    attributes: [:id, :tag_kind, :value, :event_id],
    index: [:tag_kind, :value, :event_id],
    type: :ordered_set,
    autoincrement: true

  alias Memento.Query
  alias Memento.Table
  alias Noxir.Store.Event

  @type id :: integer()
  @type tag_kind :: binary()
  @type value :: binary()
  @type event_id :: binary()

  @type t :: %__MODULE__{
          id: id(),
          tag_kind: tag_kind(),
          value: value(),
          event_id: event_id()
        }

  @spec add_event(Event.t()) :: [Table.record() | no_return()]
  def add_event(%Event{id: event_id, tags: tags}) do
    Enum.map(tags, fn [tag_kind, value | _] ->
      add_event(tag_kind, value, event_id)
    end)
  end

  @spec add_event(tag_kind(), value(), event_id()) :: Table.record() | no_return()
  def add_event(tag_kind, value, event_id) do
    case Query.select(__MODULE__, [
           {:==, :tag_kind, tag_kind},
           {:==, :value, value},
           {:==, :event_id, event_id}
         ]) do
      [] ->
        Query.write(%__MODULE__{
          tag_kind: tag_kind,
          value: value,
          event_id: event_id
        })

      [current | _] ->
        current
    end
  end

  @spec remove_event(Event.t()) :: :ok
  def remove_event(%Event{id: event_id, tags: tags}) do
    Enum.each(tags, fn [tag_kind, value | _] ->
      remove_event(tag_kind, value, event_id)
    end)
  end

  @spec remove_event(tag_kind(), value(), event_id()) :: :ok
  def remove_event(tag_kind, value, event_id) do
    __MODULE__
    |> Query.select([{:==, :tag_kind, tag_kind}, {:==, :value, value}, {:==, :event_id, event_id}])
    |> Enum.each(&Query.delete_record/1)
  end
end
