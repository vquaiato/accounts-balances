defmodule AccountsDepositTest do
  use ExUnit.Case
  alias Decimal, as: D

  describe "deposit_to user with negative value" do
    test "returns an error" do
      Accounts.start([])
      assert {:error, :invalid_operation} = Accounts.deposit_to(:foo, -1)
    end
  end

  describe "deposit_to user an amount of 0" do
    test "returns :no_change" do
      Accounts.start([])
      assert {:ok, :no_change} = Accounts.deposit_to(:foo, 0)
    end
  end

  describe "deposit_to user an amount greater than 0" do
    test "returns the confirmation of deposited amount" do
      Accounts.start([])
      amount = D.new(10)
      {:ok, deposited} = Accounts.deposit_to(:foo, amount)

      assert D.equal?(deposited, amount)
    end
  end

  describe "deposit_to user with decimal places balance" do
    test "adds correct decimal places to balance" do
      Accounts.start([])
      Accounts.deposit_to(:foo, 10.77)

      Accounts.deposit_to(:foo, 10.14)

      {:ok, balance_with_decimals} = Accounts.balance_for(:foo)
      assert balance_with_decimals == D.new(20.91)
    end
  end
end
