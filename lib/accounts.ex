defmodule Accounts do
  use Agent
  alias Decimal, as: D

  @name __MODULE__

  @moduledoc """
  Documentation for Accounts.
  """

  @doc """
  Start Accounts name (name.start_link) with an empty set.
  Should only be called by the application when initing itself.

  Sets the accounts to an empty set, all previous execution's data will be lost as it is only maintained in-memory.
  """
  def start(_), do: start_link([])

  def start_link(_) do
    D.set_context(%D.Context{D.get_context() | precision: 4})
    Agent.start_link(fn -> %{} end, name: @name)
  end

  @doc """
    Shows the user's current balance. Ex: {:ok, 0} or {:ok, 10.00}

    As a design choice, requesting a balance for an user that never has deposited returns 0. The idea is to show that business decisions need to be made both on cases like this and the withdraw (that implements a different rule, to illustrate a different line of thought).
  """
  def balance_for(user) do
    %{:balance => b} = get_account_for(user, Agent.get(@name, & &1))

    {:ok, b}
  end

  @doc "Depositing zero just returns a {:ok, :no_change}."
  def deposit_to(_user, 0), do: {:ok, :no_change}
  def deposit_to(_user, %D{coef: 0}), do: {:ok, :no_change}

  @doc "Isn't possible to deposit negative values. A {:error, :invalid_operation} is returned."
  def deposit_to(_user, amount) when is_number(amount) and amount < 0,
    do: {:error, :invalid_operation}
  def deposit_to(_user, %D{coef: c}) when c < 0, do: {:error, :invalid_operation}

  @doc "Deposits the amount to the given user account balance."
  def deposit_to(user, amount) when is_integer(amount), do: deposit_to(user, D.new(amount))
  def deposit_to(user, amount) when is_float(amount), do: deposit_to(user, D.from_float(amount))

  def deposit_to(user, %D{} = amount) do
    Agent.cast(@name, fn state ->
      %{balance: balance, withdraw: w} = get_account_for(user, state)
      Map.put(state, user, %{balance: D.add(amount, balance), withdraw: w})
    end)

    {:ok, amount}
  end

  @doc """
    Withdraws amount from user current balance.

    When user has less than requested for withdraw the operation isn't realized. A {:error, :no_funds} is returned. Otherwise {:ok, amount} is returned.

    As a design choice, to ilustrate a line that could be implemented, if a withdraw is requested from an user that never has deposited, instead of returning :no_funds is returned :invalid_operation, as if that account doesn't exist.
  """
  def withdraw_from(user, amount) when is_integer(amount), do: withdraw_from(user, D.new(amount))
  def withdraw_from(user, amount) when is_float(amount), do: withdraw_from(user, D.from_float(amount))
  def withdraw_from(user, %D{} = amount) do
    Agent.update(@name, fn
      %{^user => %{balance: balance}} = state when balance < amount ->
        Map.put(state, user, %{balance: balance, withdraw: :no_funds})

      %{^user => %{balance: balance}} = state ->
        Map.put(state, user, %{balance: D.sub(balance, amount), withdraw: :ok})

      state ->
        state
    end)

    case Agent.get(@name, & &1) do
      %{^user => %{withdraw: :no_funds}} -> {:error, :no_funds}
      %{^user => %{withdraw: :ok}} -> {:ok, amount}
      _invalid -> {:error, :invalid_operation}
    end
  end

  defp get_account_for(user, map),
    do: Map.get_lazy(map, user, fn -> %{balance: D.new(0), withdraw: :none} end)
end
