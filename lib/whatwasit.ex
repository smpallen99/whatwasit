defmodule Whatwasit do
  @moduledoc """
  Track changes on Ecto Models.

  Whatwasit is a package for tracking changes to your project's Ecto models for
  auditing or versioning. Keep track of each change to your model and who made the
  change. Deletes can be tracked too.

  Simply add a 2 line change to each model you would like tracked and a version
  record will be inserted into the database for each change.

      defmodule MyProject.Post do
        use MyProject.Web, :model
        use Whatwasit            # add this

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

  Pass a changeset into Repo.delete and a version record will be inserted into
  the database when a model is deleted.

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

  You can also track who made the change with a few extra changes.

  Install with the `--whodoneit` option:

      mix whodoneit.install --whodoneit

  Update the model

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

  Update the controller

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

  Retrieve the versions for a specific record:

      iex(4)> post = MyProject.Repo.get MyProject.Post, 9

      %MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
       body: "The answer is 42", id: 9,
       inserted_at: #Ecto.DateTime<2016-07-22 01:49:25>, title: "What's the Question",
       updated_at: #Ecto.DateTime<2016-07-22 01:49:55>}

      iex(5)> MyProject.Post.versions post

      [%MyProject.Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">, body: "42",
        id: 9, inserted_at: "2016-07-22T01:49:25", title: "The Answer",
        updated_at: "2016-07-22T01:49:25"}]


  """

  defmacro __using__(_opts \\ []) do
    base =  Mix.Project.get |> Module.split |> Enum.reverse |> Enum.at(1)
    version_module = Module.concat([base, Whatwasit, Version])
    quote do
      import unquote(version_module)
    end
  end
end
