Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Whatwasit.InstallTest do
  use ExUnit.Case
  alias Coherence.Config
  import MixHelper

  @model_path "web/models/whatwasit/version.ex"

  def assert_schema_base(file) do
    assert file =~ "defmodule TestWhatwasit.Whatwasit.Version do"
    assert file =~ ~s(schema "versions" do)
    assert file =~ "field :item_type, :string"
    assert file =~ "field :item_id, :integer"
    assert file =~ "field :action, :string"
    assert file =~ "field :object, :map"
    assert file =~ "timestamps"
  end
  def assert_migration_base(file) do
    assert file =~ "defmodule TestWhatwasit.Repo.Migrations.CreateWhatwasitVersion do"
    assert file =~ "create table(:versions) do"
    assert file =~ "add :item_type, :string, null: false"
    assert file =~ "add :item_id, :integer, null: false"
    assert file =~ "add :action, :string"
    assert file =~ "add :object, :map, null: false"
    assert file =~ "timestamps"
  end

  describe "generates migrations" do
    test "generates_migrations" do
      in_tmp "for_defaults", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--migration-path=migrations", "--module=TestWhatwasit"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          refute file =~ "add :whodoneit_name, :string"
          refute file =~ "add :whodoneit_id, references(:users, on_delete: :nilify_all)"
        end

        assert_file @model_path, fn file ->
          assert_schema_base file
          refute file =~ "field :whodoneit_name, :string"
          refute file =~ "belongs_to :whodoneit, TestWhatwasit.User"
          assert file =~ "|> cast(params, ~w(item_type item_id object action)a)"
          # assert file =~ "|> cast(params, [:item_type, :item_id, :object, :action])"
          refute file =~ "whodoneit_id whodoneit_name"
          # refute file =~ ":whodoneit_id, :whodoneit_name"
        end
      end
    end

    test "for_defaults" do
      in_tmp "for_defaults", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--whodoneit", "--migration-path=migrations", "--module=TestWhatwasit"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          assert file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit_id, references(:users, on_delete: :nilify_all)"
        end

        assert_file @model_path, fn file ->
          assert_schema_base file
          assert file =~ "field :whodoneit_name, :string"
          assert file =~ "belongs_to :whodoneit, TestWhatwasit.User"
          assert file =~ "|> cast(params, ~w(item_type item_id object action whodoneit_id whodoneit_name)a)"
        end
      end
    end

    test "model option" do
      in_tmp "model_option", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--whodoneit", "--migration-path=migrations", "--module=TestWhatwasit", "--model=Account accounts"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          assert file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit_id, references(:accounts, on_delete: :nilify_all)"
          assert file =~ "timestamps"
        end

        assert_file @model_path, fn file ->
          assert_schema_base file
          assert file =~ "field :whodoneit_name, :string"
          assert file =~ "belongs_to :whodoneit, TestWhatwasit.Account"
          assert file =~ "|> cast(params, ~w(item_type item_id object action whodoneit_id whodoneit_name)a)"
        end
      end
    end

    test "whodoneit_id set" do
      in_tmp "whodoneit_id_set", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--whodoneit", "--whodoneit-id=bigint", "--migration-path=migrations", "--module=TestWhatwasit"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          assert file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit_id, :bigint"
        end

        assert_file @model_path, fn file ->
          assert_schema_base file
          assert file =~ "field :whodoneit_name, :string"
          assert file =~ "field :whodoneit_id, :bigint"
          assert file =~ "|> cast(params, ~w(item_type item_id object action whodoneit_id whodoneit_name)a)"
        end
      end
    end

    test "no models" do
      in_tmp "no_models", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--no-models", "--whodoneit", "--whodoneit-id=bigint", "--migration-path=migrations", "--module=TestWhatwasit"]

        refute_file @model_path

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          assert file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit_id, :bigint"
        end
      end
    end

    test "no migrations" do
      in_tmp "no_migrations", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--migration-path=migrations", "--no-migrations"]

        assert Path.wildcard("migrations/*_create_whatwasit_version.exs") == []
      end
    end

    test "whodoneit-map" do
      in_tmp "whodoneit_map", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--whodoneit-map", "--migration-path=migrations", "--module=TestWhatwasit"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert_migration_base file
          refute file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit, :map"
          assert file =~ "timestamps"
        end

        assert_file @model_path, fn file ->
          assert_schema_base file
          refute file =~ "field :whodoneit_name, :string"
          assert file =~ "field :whodoneit, :map"
          assert file =~ "|> cast(params, ~w(item_type item_id object action whodoneit)a)"
        end
      end
    end
  end

end
