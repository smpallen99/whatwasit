use Mix.Config


config :logger, level: :warn

config :whatwasit,
  user_schema: TestWhatwasit.User,
  repo: TestWhatwasit.Repo,
  module: TestWhatwasit,
  version_module: TestWhatwasit.Whatwasit.Version

config :whatwasit, TestWhatwasit.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "whatwasit_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
