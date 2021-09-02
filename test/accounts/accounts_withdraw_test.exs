defmodule AccountsWithdrawTest do
  use ExUnit.Case
  alias Decimal, as: D

  describe "withdraw_from user without any deposits yet" do
    test "returns :invalid_operation" do
      Accounts.start([])
      assert {:error, :invalid_operation} = Accounts.withdraw_from(:foo, 10.00)
    end
  end

  describe "withdraw_from user with no suficient funds" do
    test "returns :no_funds" do
      Accounts.start([])
      Accounts.deposit_to(:foo, 5.00)
      assert {:error, :no_funds} = Accounts.withdraw_from(:foo, 10.00)
    end
  end

  describe "withdraw_from user with more funds than withdrawing" do
    setup do
      Accounts.start([])
      Accounts.deposit_to(:foo, 15.00)
      {:ok, []}
    end

    test "returns :ok" do
      assert {:ok, _balance} = Accounts.withdraw_from(:foo, 10.00)
    end

    test "final balance is current balance - withdrawal amount" do
      Accounts.withdraw_from(:foo, 10.00)
      {:ok, balance} = Accounts.balance_for(:foo)

      assert D.equal?(D.new(5.00), balance)
    end
  end

  describe "withdraw_from user with decimal places balance" do
    test "subtracts correct decimal places from balance" do
      Accounts.start([])
      Accounts.deposit_to(:foo, 10.77)

      Accounts.withdraw_from(:foo, 5.85)

      {:ok, balance_with_decimals} = Accounts.balance_for(:foo)
      assert balance_with_decimals == D.new(4.92)
    end
  end
end
