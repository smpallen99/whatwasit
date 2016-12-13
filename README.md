# Whatwasit

[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/smpallen99/whatwasit.svg?branch=master
[travis]: https://travis-ci.org/smpallen99/whatwasit
[hex-img]: https://img.shields.io/hexpm/v/whatwasit.svg
[hex]: https://hex.pm/packages/whatwasit
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> <div style="font-color: red">Alert: Project under active development!</div>
>
> This is an early release. So expect changes and new features in the near future.

Whatwasit is a package for tracking changes to your project's Ecto models for auditing or versioning. Keep track of each change to your model and who made the change. Deletes can be tracked too.

## Installation

Add the dependency to `mix.exs`:

```elixir
defp deps do
   ...
   {:whatwasit, "~> 0.2"},
   ...
end
```

Get the dependency:

```bash
mix deps.get
```

## Getting Started

Run the install mix task:

```bash
mix whatwasit.install
```

Add the config instructions to your project's `config/config.exs` file:

```elixir
# config/config.exs

config :whatwasit,
  repo: MyProject.Repo
```

Run the migration:

```bash
mix ecto.migrate
```

Add whatwasit to each model you would like to track:

```elixir
# web/models/post.ex

defmodule MyProject.Post do
  use MyProject.Web, :model
  use Whatwasit          # add this

  schema "posts" do
    field :title, :string
    field :body, :string
    timestamps
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(title body))
    |> validate_required(~w(title body)a)
    |> prepare_version    # add this
  end
end
```

After editing a post, you can view all the versions for all models:

```iex
iex(1)> MyProject.Repo.all MyProject.Whatwasit.Version
[%MyProject.Whatwasit.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  action: "update", id: 16, inserted_at: #Ecto.DateTime<2016-07-22 01:49:55>,
  item_id: 9, item_type: "Post",
  object: %{"body" => "42", "id" => 9, "inserted_at" => "2016-07-22T01:49:25",
    "title" => "The Answer", "updated_at" => "2016-07-22T01:49:25"},
  updated_at: #Ecto.DateTime<2016-07-22 01:49:55>,
  whodoneit: #Ecto.Association.NotLoaded<association :whodoneit is not loaded>,
  }]
```

Alternatively you retrieve a list of versioned models with:

```iex
iex(1)> post = MyProject.Repo.get MyProject.Post, 9
%MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
 body: "The answer is 42", id: 9,
 inserted_at: #Ecto.DateTime<2016-07-22 01:49:25>, title: "What's the Question",
 updated_at: #Ecto.DateTime<2016-07-22 01:49:55>}

iex(2)> MyProject.Whatwasit.Version.versions post
[%MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">, body: "42",
  id: 9, inserted_at: "2016-07-22T01:49:25", title: "The Answer",
  updated_at: "2016-07-22T01:49:25"}]
```

## Tracking Deletes

In order to track deletes you need to pass a changeset to `Repo.delete` or `Repo.delete!`.

Note that this is not the default way phoneix.gen.html created the delete action.

```elixir
defmodule MyProject.PostController do
  # ...
  def delete(conn, %{"id" => id}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset

    Repo.delete!(changeset)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end
end
```

## Tracking Who Made The Change

A few extra steps are required for tracking who made the change. The following example may be a little different based on the function you use to get the current user. The following example uses [Coherence](https://github.com/smpallen99/coherence) as the authentication package:

Install with the `--whodoneit` option:

```bash
mix whatwasit.install --whodoneit
```

Add an extra parameter to your model's changeset function and pass that to `prepare_version:

```elixir
defmodule MyProject.Post do
  use MyProject.Web, :model
  use Whatwasit
  # ...
  def changeset(model, params \\ %{}, opts \\ []) do
    model
    |> cast(params, ~w(title body))
    |> validate_required(~w(title body)a)
    |> prepare_version(opts)
  end
end

```

Pass the current user to the changeset from your controller:

```elixir
defmodule MyProject.PostController do
  # ...

  # Add this
  defp whodoneit(conn) do
    user = Coherence.current_user(conn)
    [whodoneit: user , whodoneit_name: user.name]
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params, whodoneit(conn))
    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset(%{}, whodoneit(conn))

    Repo.delete!(changeset)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

end
```

When tracking whodoneit, two fields in the Version schema are updated. A belongs_to relationship tracks the relationship with the current user and the whodoneit_name tracks the name of the current user.

The name is tracked to handle the case of deleting a user who has made modifications. When the user is deleted, the reference to the use is nullified in the Version record. But the name is still tracked for later identification of whodoneit.

The default is to use the `:name` field on the user. This can be changed by setting the `:name_field` in the configuration, or passing the `name_field: :field_name` option to `use Whatwasit.Schema`

## Store the whodoneit in the Database

The above example saves a reference to the current user in the database. You may instead want to store user data in the database. This would allow you to save user details at the time like current IP.

Use the `--whodoneit-map` option to enable this:

```bash
mix whatwasit.install --whodoneit-map
```

This option replaces the `whodoneit_id` and `whodoneit_name` fields in the Version schema with `:whodoneit :map`.

For this option, your models will be the same. However, you will need to make changes in your controller like this:

```elixir
defmodule MyProject.PostController do
  use MyProject.Web, :controller
  # ...

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params, whodoneit(conn))
    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset(%{}, whodoneit(conn))

    Repo.delete!(changeset)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  defp whodoneit(conn) do
    # remove the password fields
    whodoneit = Coherence.current_user(conn)
    |> Admin.Whatwasit.Version.remove_fields(
       ~w(password password_confirmation password_hash)a)
    [whodoneit: whodoneit]
  end
end
```
## Whodoneit Model with Primary Key Type uuid

If your user model has a uuid primary key type of uuid, use the `--whodoneit-id-type=uuid` install option:

```bash
mix whatwasit.install --whodoneit-id-type=uuid
```

This will create the correct association type in the migration file as well as the Version shema file.

## License

`whatwasit` is Copyright (c) 2016 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
