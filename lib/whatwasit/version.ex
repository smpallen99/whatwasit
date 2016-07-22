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
    field :whodoneit_name, :string  # store name also to track if user is later deleted
    belongs_to :whodoneit, Application.get_env(:whatwasit, :user_schema)

    timestamps
  end

  @doc """
  Create a changeset for the version record
  """
  def changeset(model, params \\ %{}) do
    params = update_in params, [:object], &(Map.delete(&1, :__meta__) |> Map.delete(:__struct__))
    model
    |> cast(params, ~w(item_type item_id object whodoneit_id action whodoneit_name))
    |> validate_required(~w(item_type item_id object)a)
  end
end
