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

  test "diff" do
    {one, two} = Utils.diff("This is a test", "this was a test")
    assert one == "<span class='del'>T</span>his <span class='del'>i</span>s a test"
    assert two == "<span class='ins'>t</span>his <span class='ins'>wa</span>s a test"

    {one, two} = Utils.diff("This is a test", "something different")
    assert one == "<span class='del'>T</span>hi<span class='del'>s</span> i<span class='del'>s a t</span>e<span class='del'>s</span>t"
    assert two == "<span class='ins'>somet</span>hi<span class='ins'>ng</span> <span class='ins'>d</span>i<span class='ins'>ff</span>e<span class='ins'>ren</span>t"

    {one, two} = Utils.diff("", "Hello")
    assert one == ""
    assert two == "<span class='ins'>Hello</span>"
  end
end
