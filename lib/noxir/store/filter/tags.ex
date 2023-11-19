defmodule Noxir.Store.Filter.Tags do
  @moduledoc false

  alias Noxir.Store.Filter

  defmacro __using__(params) do
    single_lowercase_letters = Enum.map(?a..?z, &to_string([&1]))
    single_uppercase_letters = Enum.map(?A..?Z, &to_string([&1]))
    single_letters = single_lowercase_letters ++ single_uppercase_letters

    Enum.map([:pre | single_letters], fn
      :pre ->
        quote do
          @tag_filters unquote(Enum.map(single_letters, &:"##{&1}"))
          @parameters [unquote_splicing(params) | @tag_filters]

          defstruct @parameters

          attrs =
            Enum.map_join(@parameters, ",", fn
              :kinds -> ":kinds => [integer()]"
              attr when attr in [:since, :until, :limit] -> "#{inspect(attr)} => integer()"
              attr -> "#{inspect(attr)} => [binary()]"
            end)

          @type t :: unquote(:unquote)(Code.string_to_quoted!("%__MODULE__{#{attrs}}"))
        end

      tag ->
        atom_tag = :"##{tag}"

        quote do
          defp match_tags?(unquote(atom_tag), %Filter{unquote(atom_tag) => filter}, _)
               when is_nil(filter),
               do: true

          defp match_tags?(unquote(atom_tag), %Filter{unquote(atom_tag) => filter}, tags) do
            Enum.any?(tags, fn
              [unquote(tag), value | _] -> Enum.any?(filter, &(&1 == value))
              _ -> false
            end)
          end
        end
    end)
  end
end
