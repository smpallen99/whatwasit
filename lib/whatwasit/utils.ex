defmodule Whatwasit.Utils do

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
end
