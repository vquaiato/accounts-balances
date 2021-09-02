defmodule Accounts.Router do
  @success_status 200
  @bad_status 400

  use Plug.Router
  require Logger
  alias Decimal, as: D

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["text/*"], json_decoder: Poison)
  plug(:match)
  plug(:dispatch)

  def init(options), do: options

  get "/:user/balance" do
    {:ok, balance} = Accounts.balance_for(String.to_atom(user))

    send_resp(conn, @success_status, Poison.encode!(%{user: user, balance: D.to_string(balance)}))
  end

  put "/:user/operation" do
    params = conn.body_params

    case parse_params(params) do
      {:ok, amount, op} ->
        result =
          case do_account_operation(String.to_atom(user), op, amount) do
            {:ok, result} ->
              %{operation: params["operation"], status: :ok, result: D.to_string(result)}

            {:error, reason} ->
              %{operation: params["operation"], status: :error, result: reason}
          end

        send_resp(conn, @success_status, Poison.encode!(result))

      _ ->
        send_resp(conn, @bad_status, Poison.encode!(%{error: "Bad request"}))
    end
  end

  defp do_account_operation(user, :deposit, amount), do: Accounts.deposit_to(user, amount)
  defp do_account_operation(user, :withdraw, amount), do: Accounts.withdraw_from(user, amount)

  defp parse_params(%{"amount" => amount, "operation" => op})
       when op in ["deposit", "withdraw"] do
    case D.parse(to_string(amount)) do
      {:ok, parsed_amount} -> {:ok, parsed_amount, String.to_atom(op)}
      _ -> {:error, :invalid_amout, String.to_atom(op)}
    end
  end

  defp parse_params(_), do: {:error}

  match(_, do: send_resp(conn, 404, "Oops!"))
end
