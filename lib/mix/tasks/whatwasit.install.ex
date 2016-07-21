defmodule Mix.Tasks.Whatwasit.Install do
  @moduledoc """


  """

  @shortdoc "Configure the Whatwasit Package"

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Whatwasit.Mix.Utils

  @default_options ~w()
  # the options that default to true, and can be disabled with --no-option
  @default_booleans  ~w(config migrations boilerplate)

  # all boolean_options
  @boolean_options   @default_booleans

  @switches [repo: :string, migration_path: :string, model: :string, module: :string] ++ Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))
  @switch_names Enum.map(@switches, &(elem(&1, 0)))


  def run(args) do
    {opts, parsed, unknown} = OptionParser.parse(args, switches: @switches)
    IO.puts "opts: #{inspect opts}, parsed: #{inspect parsed}"

    verify_args!(parsed, unknown)

    {bin_opts, opts} = parse_options(opts)

    do_config(opts, bin_opts)
    |> do_run
  end

  def do_run(config) do
    IO.puts "config: #{inspect config}"
    config
    |> gen_migration
  end

  defp gen_migration(%{migrations: true, boilerplate: true} = config) do
    # name = config[:user_schema]
    # |> module_to_string
    # |> String.downcase
    # {verb, migration_name, initial_fields, constraints} = create_or_alter_model(config, name)
    do_gen_migration config, "create_whatwasit_version", fn repo, _path, file, name ->

      change = """
          create table(:versions) do
            add :item_type, :string, null: false
            add :item_id, :integer, null: false
            add :action, :string
            add :object, :map, null: false
            add :whodoneit_name, :string
            add :whodoneit_id, references(:users, on_delete: :nilify_all)

            timestamps
          end
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
    end
  end
  defp gen_migration(config), do: config

  defp do_gen_migration(config, name, fun) do
    timestamp = timestamp()
    repo = config[:repo]
    |> String.split(".")
    |> Module.concat
    ensure_repo(repo, [])
    path = case config[:migration_path] do
      path when is_binary(path) -> path
      _ ->
        Path.relative_to(migrations_path(repo), Mix.Project.app_path)
    end
    file = Path.join(path, "#{timestamp}_#{underscore(name)}.exs")
    fun.(repo, path, file, name)
    config
    #Map.put(config, :timestamp, timestamp + 1)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def change do
  <%= @change %>
    end
  end
  """

  #############
  # Config

  # defp do_config(opts, []) do
  #   IO.puts "do_config defaults"
  #   do_config(opts, list_to_atoms(@default_options))
  # end
  defp do_config(opts, bin_opts) do
    IO.puts "do_config bin_opts: #{inspect bin_opts}"
    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect

    # IO.puts "binding: #{inspect binding}"

    base = opts[:module] || binding[:base]
    opts = Keyword.put(opts, :base, base)
    repo = (opts[:repo] || "#{base}.Repo")

    binding = Keyword.put binding ,:base, base

    user_schema = parse_model(opts[:model], base, opts)

    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:base, base)
    |> Map.put(:user_schema, user_schema)
    |> Map.put(:repo, repo)
    |> Map.put(:binding, binding)
    |> Map.put(:migration_path, opts[:migration_path])
    |> Map.put(:module, opts[:module])
    |> do_default_config(opts)
  end

  defp parse_options(opts) do
    {opts_bin, opts} = Enum.reduce opts, {[], []}, fn
      opt, {acc_bin, acc} ->
        {acc_bin, [opt | acc]}
    end
    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map opts, &(elem(&1, 0))
    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
            {opts_bin, opts}
    else
      list -> raise_option_errors(list)
    end
  end

  ################
  # Utilities

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp do_default_config(config, opts) do
    list_to_atoms(@default_booleans)
    |> Enum.reduce( config, fn opt, acc ->
      Map.put acc, opt, Keyword.get(opts, opt, true)
    end)
  end

  defp list_to_atoms(list), do: Enum.map(list, &(String.to_atom(&1)))

  defp parse_model(model, _base, opts) when is_binary(model) do
    prefix_model model, opts
  end
  defp parse_model(_, base, _) do
    {"#{base}.User", :users}
  end
  defp paths do
    [".", :whatwasit]
  end

  defp prefix_model(model, opts) do
    module = opts[:module] || opts[:base]
    if String.starts_with? model, module do
      model
    else
      module <> "." <>  model
    end
  end

  defp raise_option(option) do
    Mix.raise """
    Invalid option --#{option}
    """
  end

end
