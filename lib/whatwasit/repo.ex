defmodule Whatwasit.Repo do

  defmacro __using__(_opts \\ []) do
    quote do
      @base Mix.Project.get |> Module.split |> Enum.reverse |> Enum.at(1)
      @version_module Module.concat([@base, Whatwasit, Version])
      alias Ecto.Multi
      def insert_with_version(%Ecto.Changeset{} = changeset, opts \\ []) do
        repo = opts[:repo] || changeset.repo || Application.get_env(:whatwasit, :repo)
        res = Multi.new
        |> Multi.insert(:insert, changeset)
        |> Multi.run(:version, unquote(__MODULE__), :insert_version, [@version_module, repo, opts])
        |> repo.transaction
        |> unquote(__MODULE__).handle_result(:insert)
      end
      def update_with_version(%Ecto.Changeset{} = changeset, opts \\ []) do
        repo = opts[:repo] || changeset.repo || Application.get_env(:whatwasit, :repo)
        res = Multi.new
        |> Multi.update(:update, changeset)
        |> Multi.run(:version, unquote(__MODULE__), :insert_version, [@version_module, repo, opts])
        |> repo.transaction
        |> unquote(__MODULE__).handle_result(:update)
      end
      def delete_with_version(changeset, opts \\ []) do
        repo = opts[:repo] || Application.get_env(:whatwasit, :repo)
        Multi.new
        |> Multi.delete(:delete, changeset)
        |> Multi.run(:version, unquote(__MODULE__), :insert_version, [@version_module, repo, opts])
        |> repo.transaction
        |> unquote(__MODULE__).handle_result(:delete)
      end
    end
  end

  def insert_version(changes, module, repo, opts) do
    [{action, model}] = Map.to_list changes
    {id, name} = module.get_whodoneit_name_and_id opts
    changeset = module.version_changeset(model, id, name, action)
    apply(repo, :insert, [changeset])
    |> case do
      {:ok, _} -> {:ok, model}
      error -> error
    end
  end

  def handle_result(result, action) do
    case result do
      {:error, _, changeset, _} -> {:error, changeset}
      {:ok, %{} = res} -> {:ok, res[action]}
    end
  end
end
