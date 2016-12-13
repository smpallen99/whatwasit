defmodule Whatwasit.Utils do
  @moduledoc false

  def cast(%{} = schema, params) do
    struct schema, map_to_atom_keys(params)
  end
  def cast(module, params) when is_atom(module), do: cast(module.__struct__, params)

  def map_to_atom_keys(%{} = params) do
    Enum.reduce(params, %{}, fn({k, v}, acc) ->
      Map.put(acc, to_atom(k), v)
    end)
  end

  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key) when is_binary(key), do: String.to_existing_atom(key)

  def item_type(%{} = item), do: item_type(item.__struct__)
  def item_type(item) do
    Module.split(item)
    |> Enum.reverse
    |> hd
    |> to_string
  end

  def diff(string1, string2) do
    res = String.myers_difference(string1, string2)
    # IO.inspect res
    res |> Enum.reduce({"", ""}, fn
      {:del, del}, {string1, string2} ->
        {string1 <> wrap(del, :del), string2 }
      {:ins, ins}, {string1, string2} ->
        {string1, string2 <> wrap(ins, :ins)}
      {:eq, eq}, {string1, string2} ->
        {string1 <> eq, string2 <> eq}
    end)
  end

  def wrap(string, class) do
    tag = "span"
    "<" <> tag <> " class='#{class}'>" <> string <> "</" <> tag <> ">"
  end
end
