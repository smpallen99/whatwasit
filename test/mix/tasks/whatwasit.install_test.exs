Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Whatwasit.InstallTest do
  use ExUnit.Case
  alias Coherence.Config
  import MixHelper


  describe "generates migrations" do
    test "for_defaults" do
      in_tmp "for_defaults", fn ->
        Mix.Tasks.Whatwasit.Install.run ["--migration-path=migrations", "--module=TestWhatwasit"]

        assert [migration] = Path.wildcard("migrations/*_create_whatwasit_version.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestWhatwasit.Repo.Migrations.CreateWhatwasitVersion do"
          assert file =~ "create table(:versions) do"
          assert file =~ "add :item_type, :string, null: false"
          assert file =~ "add :item_id, :integer, null: false"
          assert file =~ "add :action, :string"
          assert file =~ "add :object, :map, null: false"
          assert file =~ "add :whodoneit_name, :string"
          assert file =~ "add :whodoneit_id, references(:users, on_delete: :nilify_all)"
          assert file =~ "timestamps"
        end
      end
    end
  end

end
