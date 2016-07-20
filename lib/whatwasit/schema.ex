defmodule Whatwasit.Schema do
  require Ecto.Query
  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)

      @opts unquote(opts)

      def versions(schema, @opts) do
        Whatwasit.Schema.versions(schema, @opts)
      end
    end
  end

  def versions(schema, opts \\ []) do
    repo = opts[:repo] || Application.get_env(:whatwasit, :repo)
    id = schema.id
    type = Whatwasit.Utils.item_type schema
    Ecto.Query.where(Admin.Version, [a], a.item_id == ^id and a.item_type == ^type)
    |> Ecto.Query.order_by(desc: :id)
    |> repo.all
    |> Enum.map(fn item ->
      Whatwasit.Utils.cast(schema, item.object)
    end)
  end
end
