defmodule <%= base %>.Whatwasit.Version do
  @moduledoc """
  Version schema for tracking model versions.

  """
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  require Ecto.Query

  @base Mix.Project.get |> Module.split |> Enum.reverse |> Enum.at(1)
  @version_module Module.concat([@base, Whatwasit, Version])

  schema "versions" do
    field :item_type, :string
    field :item_id, :integer
    field :action, :string  # ~w(update delete)
    field :object, :map     # versioned schema stored as a map
    <%= schema_fields %>
    timestamps
  end

  @doc """
  Create a changeset for the version record
  """
  def changeset(model, params \\ %{}) do
    params = update_in params, [:object], &(remove_fields(&1))
    model
    |> cast(params, <%= changeset_fields %>)
    |> validate_required(~w(item_type item_id object)a)
  end

  defp remove_fields(model) do
    model.__struct__.__schema__(:associations)
    |> Enum.reduce(model, &(Map.delete(&2, &1)))
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)
  end

  @doc """
  Helper function to add Version record on update and delete.

  Inserts the version record.
  """
  def prepare_version(changeset, opts \\ []) do
    changeset
    |> Ecto.Changeset.prepare_changes(fn
      %{action: :update} = changeset ->
        insert_version(changeset, "update", opts)
      %{action: :delete} = changeset ->
        insert_version(changeset, "delete", opts)
      changeset ->
        changeset
    end)
  end

  @doc """
  Insert a new version record in the database
  """
  def insert_version(changeset, action, opts) do
    {whodoneit_id, name} = get_whodoneit_name_and_id(opts)
    version_changeset(changeset, whodoneit_id, name, action)
    |> changeset.repo.insert!
    changeset
  end

  @doc """
  Helper function to return a list of versioned records.
  """
  def versions(schema, opts \\ []) do
    repo = opts[:repo] || Application.get_env(:whatwasit, :repo)
    id = schema.id
    type = Whatwasit.Utils.item_type schema
    Ecto.Query.where(@version_module, [a], a.item_id == ^id and a.item_type == ^type)
    |> Ecto.Query.order_by(desc: :id)
    |> repo.all
    |> Enum.map(fn item ->
      Whatwasit.Utils.cast(schema, item.object)
    end)
  end

  @doc false
  def version_changeset(struct, whodoneit_id, name, action) do
    version_module = @version_module
    model = case struct do
      %{data: data} -> data
      model -> model
    end
    type = item_type model
    version_module.changeset(version_module.__struct__,
      %{
        item_type: type ,
        item_id: model.id,
        object: model,
        action: "#{action}",
        whodoneit_id: whodoneit_id,
        whodoneit_name: name
      })
  end

  @doc false
  def item_type(%{} = item), do: item_type(item.__struct__)
  def item_type(item) do
    Module.split(item)
    |> Enum.reverse
    |> hd
    |> to_string
  end

  @doc false
  def get_whodoneit_name_and_id(opts) do
    case Keyword.get(opts, :whodoneit) do
      nil ->
        {nil, nil}
      %{} = user ->
        id = Map.get(user, user.__struct__.__schema__(:primary_key) |> hd)

        {id, opts[:whodoneit_name]}
    end
  end
end
