defmodule Whatwasit.Repo do
  alias Whatwasit.Version

  defmacro __using__(opts \\ []) do
    repo = opts[:repo] || Application.get_env(:whatwasit, :repo)
    name_field = opts[:name_field] || Application.get_env(:whatwasit, :name_field, :name)

    unless repo do
      raise "A repo must be provided"
    end

    quote location: :keep do
      alias Whatwasit.Version

      # defoverridable [update!: 2, update: 2, delete!: 2, delete: 2]

      def update(struct, opts \\ []) do
        {whodoneit_id, name, opts} = Whatwasit.Repo.get_whodoneit_id(opts, unquote(name_field))

        case Ecto.Repo.Schema.update(__MODULE__, @adapter, struct, opts) do
          {:ok, model} ->
            Whatwasit.Repo.version_changeset(struct, whodoneit_id, name, "update")
            |> unquote(repo).insert!
            {:ok, model}
          error -> error
        end
      end

      def update!(struct, opts \\ []) do
        {whodoneit_id, name, opts} = Whatwasit.Repo.get_whodoneit_id(opts, unquote(name_field))

        model = Ecto.Repo.Schema.update!(__MODULE__, @adapter, struct, opts)

        Whatwasit.Repo.version_changeset(struct, whodoneit_id, name, "update")
        |> unquote(repo).insert!
        model
      end

      def delete(struct, opts \\ []) do
        {whodoneit_id, name, opts} = Whatwasit.Repo.get_whodoneit_id(opts, unquote(name_field))
        case Ecto.Repo.Schema.delete(__MODULE__, @adapter, struct, opts) do
          {:ok, model} ->
            Whatwasit.Repo.version_changeset(struct, whodoneit_id, name, "delete")
            |> unquote(repo).insert!
            {:ok, model}
          error -> error
        end
      end

      def delete!(struct, opts \\ []) do
        {whodoneit_id, name, opts} = Whatwasit.Repo.get_whodoneit_id(opts, unquote(name_field))

        model = Ecto.Repo.Schema.delete!(__MODULE__, @adapter, struct, opts)

        Whatwasit.Repo.version_changeset(struct, whodoneit_id, name, "delete")
        |> unquote(repo).insert!
        model
      end

    end
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
    case Keyword.pop(opts, :whodoneit) do
      {nil, opts} ->
        {nil, nil, opts}
      {%{} = user, opts} ->
        id = Map.get(user, user.__struct__.__schema__(:primary_key) |> hd)
        name = Map.get(user, name_field)
        {id, name, opts}
    end
  end
end
