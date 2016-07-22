defmodule TestWhatwasit.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    timestamps
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(email name))
    |>validate_required(~w(email name)a)
  end
end

defmodule TestWhatwasit.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :full_name, :string
    field :email, :string
    timestamps
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(email full_name))
    |>validate_required(~w(email full_name)a)
  end
end

defmodule TestWhatwasit.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    timestamps
  end

  def changeset(model, params \\ %{}, opts \\ []) do
    model
    |> cast(params, ~w(title body))
    |> validate_required(~w(title body)a)
    |> Whatwasit.Whatwasit.Version.prepare_version(opts)
  end
end
