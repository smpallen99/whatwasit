ExUnit.start()

Code.require_file "./support/migrations.exs", __DIR__
Code.require_file "./support/schema.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__

defmodule Whatwasit.RepoSetup do
  use ExUnit.CaseTemplate
end

{:ok, _pid} = TestWhatwasit.Repo.start_link

TestWhatwasit.Repo.__adapter__.storage_down TestWhatwasit.Repo.config
TestWhatwasit.Repo.__adapter__.storage_up TestWhatwasit.Repo.config

_ = Ecto.Migrator.up(TestWhatwasit.Repo, 0, TestWhatwasit.Migrations, log: false)
Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(TestWhatwasit.Repo, :manual)
