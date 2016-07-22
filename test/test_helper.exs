ExUnit.start()

Code.require_file "./support/model_case.exs", __DIR__
Code.require_file "./support/migrations.exs", __DIR__
Code.require_file "./support/schema.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__
Code.require_file "./support/test_helpers.exs", __DIR__

defmodule Whatwasit.RepoSetup do
  use ExUnit.CaseTemplate
end


TestWhatwasit.Repo.__adapter__.storage_down TestWhatwasit.Repo.config
TestWhatwasit.Repo.__adapter__.storage_up TestWhatwasit.Repo.config

{:ok, _pid} = TestWhatwasit.Repo.start_link

_ = Ecto.Migrator.up(TestWhatwasit.Repo, 0, TestWhatwasit.Migrations)
# _ = Ecto.Migrator.up(TestWhatwasit.Repo, 0, TestWhatwasit.Migrations, log: false)
Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(TestWhatwasit.Repo, :manual)
