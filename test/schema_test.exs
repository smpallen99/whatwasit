defmodule Whatwasit.Whatwasit.Version do
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  require Ecto.Query
  require Logger

  @base Mix.Project.get |> Module.split |> Enum.reverse |> Enum.at(1)
  @version_module Module.concat([@base, Whatwasit, Version])

  schema "versions" do
    field :item_type, :string
    field :item_id, :integer
    field :action, :string
    field :object, :map
    field :whodoneit_name, :string
    belongs_to :whodoneit, TestWhatwasit.User
    timestamps
  end

  @doc """
  Create a changeset for the version record
  """
  def changeset(model, params \\ %{}) do
    params = update_in params, [:object], &(remove_fields(&1))
    model
    |> cast(params, ~w(item_type item_id object action whodoneit_id whodoneit_name))
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

defmodule TestWhatwasit.SchemaTest do
  use TestWhatwasit.ModelCase
  import TestWhatwasit.TestHelpers
  alias TestWhatwasit.{Post, AuditedPost}
  alias Whatwasit.Whatwasit.Version

  def setup_tracking(_) do
    user = insert_user
    post = insert_post
    {:ok, post: post, user: user}
  end

  describe "track changes mode" do
    setup [:setup_tracking]

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
      {:ok, _post} = Post.changeset(post, %{title: "new title"}, whodoneit: user, whodoneit_name: user.name)
      |> Repo.update
      [version] = Repo.all(Version) |> Repo.preload([:whodoneit])
      assert version.object["title"] == title
      assert version.whodoneit_name == user.name
      assert version.whodoneit.id == user.id
      assert version.action == "update"
    end

    test "prepare_version delete with user", %{post: post, user: user} do
      title = post.title
      _ = Post.changeset(post, %{}, whodoneit: user, whodoneit_name: user.name)
      |> Repo.delete!
      [version] = Repo.all(Version) |> Repo.preload([:whodoneit])
      assert version.object["title"] == title
      assert version.whodoneit_name == user.name
      assert version.whodoneit.id == user.id
      assert version.action == "delete"
    end

    test "versions", %{post: post1} do
      title1 = post1.title
      post2 = insert_post
      title2 = post2.title

      post1 = Post.changeset(post1, %{title: "one"})
      |> Repo.update!
      Post.changeset(post1, %{title: "two"})
      |> Repo.update!
      Post.changeset(post2, %{title: "three"})
      |> Repo.update!

      [v12, v11] = Version.versions post1
      [v21] = Version.versions post2

      assert v12.title == "one"
      assert v11.title == title1
      assert v21.title == title2
    end
  end

  def setup_audit_mode(_) do
    {:ok, post} = AuditedPost.changeset(%AuditedPost{}, %{title: "title", body: "body"})
    |> Repo.insert_with_version
    {:ok, post: post}
  end

  describe "Model Audit Mode" do
    setup [:setup_audit_mode]
    test "insert", %{post: post} do
      post = Repo.get(AuditedPost, post.id)
      assert post.title == "title"
      assert post.body == "body"
      [v1] = Version.versions post
      assert v1.title == "title"
      assert v1.body == "body"
      [version] = Repo.all(Version)
      assert version.action == "insert"
    end

    test "update", %{post: post} do
      {:ok, post1} = AuditedPost.changeset(post, %{title: "title1", body: "body1"})
      |> Repo.update_with_version
      post = Repo.get(AuditedPost, post1.id)
      assert post.title == "title1"
      assert post.body == "body1"
      [v2,v1] = Version.versions post
      assert v1.title == "title"
      assert v1.body == "body"
      assert v2.title == "title1"
      assert v2.body == "body1"
      [v1,v2] = Repo.all(Version)
      assert v1.action == "insert"
      assert v2.action == "update"

      {:ok, post} = AuditedPost.changeset(post, %{title: "title2", body: "body2"})
      |> Repo.update_with_version
      post = Repo.get(AuditedPost, post.id)
      assert post.title == "title2"
      assert post.body == "body2"
      [v3, _v2, _v1] = Version.versions post
      assert v3.title == "title2"
      assert v3.body == "body2"
      [v1,v2,v3] = Repo.all(Version)
      assert v1.action == "insert"
      assert v2.action == "update"
      assert v3.action == "update"
    end

    test "delete", %{post: post} do
      {:ok, post} = post
      |> Repo.delete_with_version
      refute Repo.get(AuditedPost, post.id)
      [v1,v2] = Repo.all(Version)
      assert v1.action == "insert"
      assert v1.object["title"] == "title"
      assert v1.object["body"] == "body"
      assert v2.action == "delete"
      assert v2.object["title"] == "title"
      assert v2.object["body"] == "body"
    end
  end

  def setup_audit_mode_user(_) do
    user = insert_user
    {:ok, post} = AuditedPost.changeset(%AuditedPost{}, %{title: "title", body: "body"})
    |> Repo.insert_with_version(whodoneit(user))
    {:ok, post: post, user: user}
  end

  def whodoneit(user) do
    [whodoneit: user , whodoneit_name: user.name]
  end

  describe "Model Audit Mode User" do
    setup [:setup_audit_mode_user]
    test "insert", %{post: post, user: user} do
      post = Repo.get(AuditedPost, post.id)
      assert post.title == "title"
      assert post.body == "body"
      [v1] = Version.versions post
      assert v1.title == "title"
      assert v1.body == "body"
      [version] = Repo.all(Version) |> Repo.preload(:whodoneit)
      assert version.action == "insert"
      assert version.whodoneit == user
    end

    test "update", %{post: post, user: user} do
      user2 = insert_user
      {:ok, post1} = AuditedPost.changeset(post, %{title: "title1", body: "body1"})
      |> Repo.update_with_version(whodoneit(user))
      post = Repo.get(AuditedPost, post1.id)
      assert post.title == "title1"
      assert post.body == "body1"
      [v2,v1] = Version.versions post
      assert v1.title == "title"
      assert v1.body == "body"
      assert v2.title == "title1"
      assert v2.body == "body1"
      [v1,v2] = Repo.all(Version) |> Repo.preload(:whodoneit)
      assert v1.action == "insert"
      assert v2.action == "update"
      assert v1.whodoneit == user
      assert v2.whodoneit == user

      {:ok, post} = AuditedPost.changeset(post, %{title: "title2", body: "body2"})
      |> Repo.update_with_version(whodoneit(user2))
      post = Repo.get(AuditedPost, post.id)
      assert post.title == "title2"
      assert post.body == "body2"
      [v3, _v2, _v1] = Version.versions post
      assert v3.title == "title2"
      assert v3.body == "body2"
      [v1,v2,v3] = Repo.all(Version) |> Repo.preload(:whodoneit)
      assert v1.action == "insert"
      assert v1.whodoneit == user
      assert v2.action == "update"
      assert v2.whodoneit == user
      assert v3.action == "update"
      assert v3.whodoneit == user2
    end

    test "delete", %{post: post, user: user} do
      user2 = insert_user
      {:ok, post} = post
      |> Repo.delete_with_version(whodoneit(user2))
      refute Repo.get(AuditedPost, post.id)
      [v1,v2] = Repo.all(Version) |> Repo.preload(:whodoneit)
      assert v1.action == "insert"
      assert v1.object["title"] == "title"
      assert v1.object["body"] == "body"
      assert v1.whodoneit == user
      assert v2.action == "delete"
      assert v2.object["title"] == "title"
      assert v2.object["body"] == "body"
      assert v2.whodoneit == user2
    end
  end
end
