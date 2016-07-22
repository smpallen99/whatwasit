defmodule TestWhatwasit.SchemaTest do
  use TestWhatwasit.ModelCase
  import TestWhatwasit.TestHelpers
  alias TestWhatwasit.{Post}
  alias Whatwasit.Version

  setup do
    user = insert_user
    post = insert_post
    {:ok, post: post, user: user}
  end

  test "prepare_version update", %{post: post} do
    title = post.title
    {:ok, post} = Post.changeset(post, %{title: "new title"})
    |> Repo.update
    assert post.title == "new title"
    [version] = Repo.all Version
    assert version.object["title"] == title
    assert version.object["body"] == post.body
    assert version.item_id == post.id
    assert version.item_type == "Post"
    assert version.action == "update"
  end

  test "prepare_version delete", %{post: post} do
    title = post.title
    body = post.body
    {:ok, post} = Post.changeset(post, %{})
    |> Repo.delete
    [version] = Repo.all Version
    assert version.object["title"] == title
    assert version.object["body"] == body
    assert version.item_id == post.id
    assert version.item_type == "Post"
    assert version.action == "delete"
  end

  test "prepare_version update with user", %{post: post, user: user} do
    title = post.title
    {:ok, _post} = Post.changeset(post, %{title: "new title"}, whodoneit: user)
    |> Repo.update
    [version] = Repo.all(Version) |> Repo.preload([:whodoneit])
    assert version.object["title"] == title
    assert version.whodoneit_name == user.name
    assert version.whodoneit.id == user.id
    assert version.action == "update"
  end

  test "prepare_version delete with user", %{post: post, user: user} do
    title = post.title
    _ = Post.changeset(post, %{}, whodoneit: user)
    |> Repo.delete!
    [version] = Repo.all(Version) |> Repo.preload([:whodoneit])
    assert version.object["title"] == title
    assert version.whodoneit_name == user.name
    assert version.whodoneit.id == user.id
    assert version.action == "delete"
  end

end
