defmodule AccountsBalanceTest do
  use ExUnit.Case
  alias Decimal, as: D

  describe "balance_for user for first time" do
    test "returns 0" do
      Accounts.start([])

      {:ok, balance} = Accounts.balance_for(:foo)
      assert D.equal?(D.new(0), balance)
    end
  end

  describe "balance_for user after depositing" do
    test "13 and 7 returns 20" do
      Accounts.start([])

      Accounts.deposit_to(:foo, 13)
      Accounts.deposit_to(:foo, 7)

      {:ok, balance} = Accounts.balance_for(:foo)
      assert D.equal?(D.new(20), balance)
    end
  end

  describe "balance_for user after making initial deposit of 10.00" do
    test "returns total balance of 10.00" do
      Accounts.start([])

      Accounts.deposit_to(:foo, 10.00)
      {:ok, balance} = Accounts.balance_for(:foo)
      assert D.equal?(D.new(10), balance)
    end
  end
end
