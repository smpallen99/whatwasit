defmodule TestWhatwasit.TestHelpers do
  alias TestWhatwasit.{Repo, User, Post}

  def insert_user(attrs \\ %{}) do
    name = Base.encode16(:crypto.rand_bytes(8))
    changes = Dict.merge(%{
      name: "User #{name}",
      email: "user#{name}@example.com",
      }, attrs)

    %User{}
    |> User.changeset(changes)
    |> Repo.insert!
  end

  def insert_post(attrs \\ %{}) do
    title = Base.encode16(:crypto.rand_bytes(16))
    body = "Test body"
    changes = Dict.merge(%{
      title: title,
      body: body,
      }, attrs)

    %Post{}
    |> Post.changeset(changes)
    |> Repo.insert!
  end
end
