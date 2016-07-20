defmodule TestWhatwasit.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(email name))
    |>validate_required(~w(email name)a)
  end
end
