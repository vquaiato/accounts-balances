defmodule AccountsTest do
  use ExUnit.Case
  doctest Accounts

  test "can start Accounts", do: assert({:ok, _} = Accounts.start([]))
end
