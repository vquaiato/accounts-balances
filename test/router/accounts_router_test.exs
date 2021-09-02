defmodule AccountsRouterTest do
  use ExUnit.Case
  use Plug.Test
  alias Decimal, as: D

  alias Accounts.Router

  @opts Router.init([])

  defp json(map), do: Poison.encode!(map)

  describe "get :user/balance not passing an user" do
    test "returns 404" do
      conn = conn(:get, "/balance", "") |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  describe "get :user/balance for user without any deposit" do
    setup do
      Accounts.start([])
      {:ok, conn: conn(:get, "/foo/balance", "") |> Router.call(@opts)}
    end

    test "returns 200", ctx do
      conn = ctx[:conn]
      assert conn.status == 200
    end

    test "returns balance: 0", ctx do
      conn = ctx[:conn]
      assert json(%{user: :foo, balance: D.to_string(D.new(0))}) == conn.resp_body
    end
  end

  describe "get :user/balance for user with deposit of 14.99" do
    setup do
      Accounts.start([])
      Accounts.deposit_to(:foo, D.new(14.99))
      {:ok, conn: conn(:get, "/foo/balance", "") |> Router.call(@opts)}
    end

    test "returns 200", ctx do
      conn = ctx[:conn]
      assert conn.status == 200
    end

    test "returns balance: 14.99", ctx do
      conn = ctx[:conn]
      assert json(%{user: :foo, balance: D.to_string(D.new(14.99))}) == conn.resp_body
    end
  end

  describe "invalid verb to :user/balance" do
    test "POST returns 404" do
      conn = conn(:post, "/foo/balance", "") |> Router.call(@opts)
      assert conn.status == 404
    end

    test "PUT returns 404" do
      conn = conn(:put, "/foo/balance", "") |> Router.call(@opts)
      assert conn.status == 404
    end
  end

  describe "put :user/operation not passing an user" do
    test "returns 404" do
      conn = conn(:get, "/operation", "") |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  describe "put :user/operation passing operation that isnt [:deposit, :withdraw]" do
    test "returns 400" do
      resp = conn(:put, "/foo/operation", %{amount: 0, operation: "foo"}) |> Router.call(@opts)
      assert resp.status == 400
    end
  end

  describe "put :user/operation passing non-numeric amount" do
    test "returns 400" do
      resp = conn(:put, "/foo/operation", %{amount: "foo", operation: "deposit"}) |> Router.call(@opts)
      assert resp.status == 400
    end
  end

  describe "put :user/operation passing valid numeric and valid deposit operation " do
    setup do
      Accounts.start([])
      {:ok, conn: conn(:put, "/foo/operation", %{amount: "17.96", operation: "deposit"}) |> Router.call(@opts)}
    end
    test "returns 200", ctx do
      conn = ctx[:conn]
      assert conn.status == 200
    end
    test "returns json with operation, status and result", ctx do
      conn = ctx[:conn]
      assert json(%{operation: :deposit, status: :ok, result: "17.96"}) == conn.resp_body
    end
  end

  describe "put :user/operation passing valid numeric and valid withdraw operation in account without funds" do
    setup do
      Accounts.start([])
      Accounts.deposit_to(:foo, D.new(1))
      {:ok, conn: conn(:put, "/foo/operation", %{amount: "5.99", operation: "withdraw"}) |> Router.call(@opts)}
    end
    test "returns 200", ctx do
      conn = ctx[:conn]
      assert conn.status == 200
    end
    test "returns json with operation, status and result", ctx do
      conn = ctx[:conn]
      assert json(%{operation: :withdraw, status: :error, result: :no_funds}) == conn.resp_body
    end
  end

  describe "put :user/operation passing valid numeric and withdraw for user that never has made deposit" do
    setup do
      Accounts.start([])
      {:ok, conn: conn(:put, "/foo/operation", %{amount: "5.99", operation: "withdraw"}) |> Router.call(@opts)}
    end
    test "returns 200", ctx do
      conn = ctx[:conn]
      assert conn.status == 200
    end
    test "returns :error with :invalid_operation", ctx do
      conn = ctx[:conn]
      assert json(%{operation: :withdraw, status: :error, result: :invalid_operation}) == conn.resp_body
    end
  end
end
