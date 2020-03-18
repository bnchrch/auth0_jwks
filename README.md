# Auth0 JWK plug

This is an Elixir plug meant to make validating Auth0 tokens and creating users in your API as painless as possible.

# How to use

## Installation

If [available in Hex](https://hex.pm/packages/auth0_jwks), the package can be installed
by adding `auth0_jwks` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth0_jwks, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/auth0_jwks](https://hexdocs.pm/auth0_jwks).

## Using the library
### 1. Add your Auth0 config
```elixir
# config.exs
config :auth0_jwks, iss: System.get_env("AUTH0_DOMAIN"),
                    aud: System.get_env("AUTH0_AUDIENCE")
```

```bash
# .env.example

export AUTH0_DOMAIN="https://{your_app_name}.auth0.com/"

# Note this is the Identifier field found on the config of your custom API in the auth0 dashboard
# Mine was `https://{your_app_name}.auth0.com/api/v2/` yours could be `fuzzy sock 5`
export AUTH0_AUDIENCE="{your_custom_api_identified}"
```

### 2. Start your Auth0 Strategy
```elixir
# application.ex
defmodule YourApp.Application do

  use Application

  def start(_type, _args) do
    children = [
      # ...
      Auth0Jwks.Strategy
    ]

    # ...
  end
end
```

### 3. Adding the plugs
There exist two plugs:

**1. ValidateToken**

This is used to ensure the given token is valid against Auth0's public jwks and attaches the resulet to the connection object under `assigns.auth0_claims`. It also attaches the bearer token under `assigns.auth0_access_token`.

**2. GetUser**

This plug takes one option `user_from_claim` which is where you define how you want to use the information from the claim to fetch or create a user. There exists many ways to handle this so we leave it up to you.

#### Example Router & Controller

```elixir
# router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Auth0Jwks.Plug.ValidateToken
    plug Auth0Jwks.Plug.GetUser, user_from_claim: &YourApp.Accounts.user_from_claim/2
  end

  scope "/api", YourAppWeb do
    pipe_through :api
    post "/validate_token", AuthController, :validate
  end
end

# accounts.ex
defmodule YourApp.Accounts do
  def user_from_claim(claims, token) do
    # Here you should take the `sub` value from `claims` and use it to fetch a user from your database.
    # If you don't find a user then create one.
    case get_user_by_sub(claims["sub"]) do
      nil ->
        # Note: we've provided a helper method to get more information from Auth0 about your user.
        # However call it sparingly as the endpoint is rate limited.
        {:ok, auth0_user_info} = Auth0Jwks.UserInfo.from_token(token)
        create_user_from_auth0(auth0_user_info)

      existing_user ->
        existing_user
    end
  end

  def get_user_by_sub(sub) do
    # query your database or something
  end

  def create_user_from_auth0(auth0_user_info) do
    # insert into your database or something
  end

end
```

### 4. Fetching your user
```elixir
defmodule YourApp.AuthController do
  use YourAppWeb, :controller
  import Plug.Conn

  def validate(%{assigns: %{current_user: current_user}} = conn, _body) do
    IO.inspect(current_user, label: "Your current user")

    conn
    |> put_status(:accepted)
    |> json("User found with email #{current_user["email"]}")
  end
end
```
