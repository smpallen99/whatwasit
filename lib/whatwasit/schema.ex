defmodule Whatwasit.Schema do
  require Ecto.Query
  alias Whatwasit.Version

  defmacro __using__(opts \\ []) do
    name_field = opts[:name_field] || Application.get_env(:whatwasit, :name_field, :name)
    quote do


      def prepare_version(changeset, opts \\ []) do
        Whatwasit.Schema.prepare_version(changeset, Keyword.put(opts, :name_field, unquote(name_field)))
      end

      def versions(schema, opts \\ []) do
        Whatwasit.Schema.versions(schema, Keyword.merge(unquote(opts), opts))
      end
    end
  end

  def prepare_version(changeset, opts) do
    name_field = opts[:name_field]
    changeset
    |> Ecto.Changeset.prepare_changes(fn
      %{action: :update} = changeset ->
        insert_version(changeset, "update", name_field, opts)
      %{action: :delete} = changeset ->
        insert_version(changeset, "delete", name_field, opts)
      changeset ->
        changeset
    end)
  end

  defp insert_version(changeset, action, name_field, opts) do
    {whodoneit_id, name} = Whatwasit.Schema.get_whodoneit_id(opts, name_field)
    Whatwasit.Schema.version_changeset(changeset, whodoneit_id, name, action)
    |> changeset.repo.insert!
    changeset
  end

  def versions(schema, opts \\ []) do
    repo = opts[:repo] || Application.get_env(:whatwasit, :repo)
    id = schema.id
    type = Whatwasit.Utils.item_type schema
    Ecto.Query.where(Whatwasit.Version, [a], a.item_id == ^id and a.item_type == ^type)
    |> Ecto.Query.order_by(desc: :id)
    |> repo.all
    |> Enum.map(fn item ->
      Whatwasit.Utils.cast(schema, item.object)
    end)
  end

  def version_changeset(struct, whodoneit_id, name, action) do
    model = case struct do
      %{data: data} -> data
      model -> model
    end
    type = item_type model
    Version.changeset(%Version{},
      %{
        item_type: type ,
        item_id: model.id,
        object: model,
        action: "#{action}",
        whodoneit_id: whodoneit_id,
        whodoneit_name: name
      })
  end

  def item_type(%{} = item), do: item_type(item.__struct__)
  def item_type(item) do
    Module.split(item)
    |> Enum.reverse
    |> hd
    |> to_string
  end

  def get_whodoneit_id(opts, name_field) do
    case Keyword.get(opts, :whodoneit) do
      nil ->
        {nil, nil}
      %{} = user ->
        id = Map.get(user, user.__struct__.__schema__(:primary_key) |> hd)
        name = Map.get(user, name_field)
        {id, name}
    end
  end
end
