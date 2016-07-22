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

Add the dependency:

mix.exs
```elixir
  defp deps do
     ...
     {:whatwasit, github: "smpallen99/whatwasit"},
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
  repo: MyProject.Repo,
  user_schema: MyProject.User
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
  use Whatwasit.Schema     # add this

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

```bash
    iex(1)> MyProject.Repo.all Whatwasit.Version

    [%Whatwasit.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
      action: "update", id: 16, inserted_at: #Ecto.DateTime<2016-07-22 01:49:55>,
      item_id: 9, item_type: "Post",
      object: %{"body" => "42", "id" => 9, "inserted_at" => "2016-07-22T01:49:25",
        "title" => "The Answer", "updated_at" => "2016-07-22T01:49:25"},
      updated_at: #Ecto.DateTime<2016-07-22 01:49:55>,
      whodoneit: #Ecto.Association.NotLoaded<association :whodoneit is not loaded>,
      whodoneit_id: nil, whodoneit_name: nil}]
    iex(2)>
```

Alternatively you retrieve a list of versioned models with:

```bash
    iex(4)> post = MyProject.Repo.get MyProject.Post, 9

    %MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
     body: "The answer is 42", id: 9,
     inserted_at: #Ecto.DateTime<2016-07-22 01:49:25>, title: "What's the Question",
     updated_at: #Ecto.DateTime<2016-07-22 01:49:55>}

    iex(5)> MyProject.Post.versions post

    [%MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">, body: "42",
      id: 9, inserted_at: "2016-07-22T01:49:25", title: "The Answer",
      updated_at: "2016-07-22T01:49:25"}]

    iex(6)>
```

## Tracking Deletes

In order to track deletes you need to pass a changeset to `Repo.delete` or `Repo.delete!`.

Note that this is not the default way phoneix.gen.html created the delete action.

```elixir
defmodule MyProject.PostController do
  # ...
  def delete(conn, %{"id" => id}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset(%{})

    Repo.delete!(changeset)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end
end
```

## Tracking Who Made The Change

A few extra steps are required for tracking who made the change. The following example may be a little different based on the function you use to get the current user. The following example uses [Coherence](https://github.com/smpallen99/coherence) as the authentication package:

Add an extra parameter to your model's changeset function and pass that to `prepare_version:

```elixir
defmodule MyProject.Post do
  use MyProject.Web, :model
  use Whatwasit.Schema
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
defmodule Admin.PostController do
  # ...

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params, whodoneit: Coherence.current_user(conn))
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
    |> Post.changeset(%{}, whodoneit: Coherence.current_user(conn))

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

## License

`whatwasit` is Copyright (c) 2016 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
