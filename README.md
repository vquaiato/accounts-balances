# Accounts

This is the code challenge for manipulating the following operations on bank accounts:
 - Deposits;
 - Withdrawals;
 - Balance.

Exposing those operations over HTTP.

## The stack
The language I've chose is Elixir. It is functional, fun and the syntax is really pretty. I also find the pattern macth features on Elixir incredibly easy to read, making code easier to maintain.

Instead of using a full web framework to expose only two HTTP endpoints I've chose to *"build"* a simple microframework on top of `Plug` and `Cowboy`.

As a data storage I've chose Elixir's built-in `Agents`, that are wrappers around state. Agents are processes that can be supervised and are built on top of OTP to keep state. The great thing is that it can talk to other processes. It is also fast and good dealing with concurrency.

## Setting up the Elixir environment
The most reliable way to setup the environment is following the official guidelines [here](https://elixir-lang.org/install.html).

If you're on a Mac, simply run:
```
brew update
```
and then:
```
brew install elixir
```
It is generally enough.

## Restoring dependencies
After installing Elixir, to restore the project's dependencies run:
```
mix deps.get
```

## Running tests
To run all the tests:
```
mix test
```

To run only the `Accounts` module tests:
```
mix test tests/accounts
```

To run only the HTTP router tests:
```
mix test tests/router
```

## Running the application from the source code
To run the application from the source code, run the following command:
```
mix run --no-halt
```

This will start the app on [`localhost:8080`](http://localhost:8080).

### Endpoints
There are two endpoints available:
```
GET /:user/balance
```
Returns a JSON with the user and the available amount:
```
{
  "user" : "<the user>",
  "amount" : "10.00"
}
```

```
PUT /:user/operation
```
That accepts a JSON body containing the following fields:

| Field         | Description                                                        |
| ------------- |--------------------------------------------------------------------|
| amount        | the amount for the operation                                       |
| operation     | The operation to be performed. One of "withdraw" or "deposit"      |

`amount` must be a valid numeric value.

#### Returns
`400` - For invalid params

`200` - For valid params.

## Deploying
It is possible to run the application using Docker. I've generated an image and uploaded it to Docker Hub. I was asked to not put anything that can identify myself in the solution, so I have omitted the docker hub url. If needed I can provide it.

The _Dockerfile_ is something like:
```
FROM elixir

WORKDIR /accounts

ADD . /accounts

RUN tar -xzf accounts.tar.gz

EXPOSE 8080

CMD ["bin/accounts", "foreground"]
```

The `accounts.tar.gz` is the product from the release generated by (`Distillery`)[https://github.com/bitwalker/distillery], responsible for generating an Erlang/OTP release from the Elixir's Mix project.

The release generation was also made using Docker, this way the binaries are generated on the same execution environment as it will run:

```
FROM elixir

WORKDIR /accounts

ADD accounts /accounts

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix release.init
RUN MIX_ENV=prod mix release --env=prod

CMD ["iex"]
```

## Code and design decisions
I really liked the simplicity working with Plug and the ability to easily expose a few HTTP endpoint without requiring a full framework only to do that.

In the `accounts_router.ex` - the responsible for handling the HTTP part of the solution - I would like to improve the route that handles the `PUT` operations. I don't like the idea of having a nested `case`, one for params validating and the other for the actual operation processing. This is one of the first points for improvement I can highlight. There is also a small duplication that could be removed from the `parse_params` function.

Talking about the `Accounts` (`accounts.ex`) module I relied on Elixir's pattern match for function headers and also for parameters and returns destructuring features to avoid code branches. I've put comments on all the public functions because it is idiomatic in Elixir.

Business decision were made to highlight different paths that could be followed while implementing inexistent accounts. For Balances I have opted to return a value of 0, and for a Withdraw I have opted to return an :invalid_operation, as if that account didn't exist. Those are decision that should be talked to business people, I just wanted to show that.