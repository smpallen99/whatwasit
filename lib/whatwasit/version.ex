defmodule Whatwasit.Version do
  @moduledoc """
  Version schema for tracking model versions.

  """
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset

  schema "versions" do
    field :item_type, :string
    field :item_id, :integer
    field :action, :string  # ~w(update delete)
    field :object, :map     # versioned schema stored as a map
    case Application.get_env(:whatwasit, :user_schema) do
      nil -> nil
      user_schema ->
        field :whodoneit_name, :string  # store name also to track if user is later deleted
        belongs_to :whodoneit, user_schema
    end
    timestamps
  end

  @doc """
  Create a changeset for the version record
  """
  def changeset(model, params \\ %{}) do
    who_fields = if Application.get_env(:whatwasit, :user_schema),
      do: ~w(whodoneit_id whodoneit_name), else: []
    params = update_in params, [:object], &(remove_fields(&1))
    model
    |> cast(params, ~w(item_type item_id object action) ++ who_fields)
    |> validate_required(~w(item_type item_id object)a)
  end

  defp remove_fields(model) do
    model.__struct__.__schema__(:associations)
    |> Enum.reduce(model, &(Map.delete(&2, &1)))
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)
  end
end
