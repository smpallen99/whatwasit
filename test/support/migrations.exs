defmodule TestWhatwasit.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string

      timestamps
    end

    create table(:accounts) do
      add :full_name, :string
      add :email, :string

      timestamps
    end

    create table(:versions) do
      add :item_type, :string, null: false
      add :item_id, :integer, null: false
      add :action, :string
      add :object, :map, null: false
      add :whodoneit_name, :string
      add :whodoneit_id, references(:users, on_delete: :nilify_all)

      timestamps
    end

    create table(:posts) do
      add :title, :string
      add :body, :text

      timestamps
    end

  end
end
