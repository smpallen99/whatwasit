defmodule Whatwasit.UtilsTest do
  use ExUnit.Case, async: true
  alias Whatwasit.Utils
  alias TestWhatwasit.User

  test "cast struct" do
    user = Utils.cast %User{}, %{"name" => "test", "email" => "test@test.com"}
    assert user.name == "test"
    assert user.email == "test@test.com"
    assert :name in user.__struct__.__schema__(:fields)
  end

  test "cast module" do
    user = Utils.cast User, %{"name" => "test", "email" => "test@test.com"}
    assert user.name == "test"
    assert user.email == "test@test.com"
    assert :name in user.__struct__.__schema__(:fields)

  end

  test "map_to_atom_keys" do
    params = %{"one" => "1", "two" => "2", three: 3}
    assert Utils.map_to_atom_keys(params) == %{one: "1", two: "2", three: 3}
  end
end
