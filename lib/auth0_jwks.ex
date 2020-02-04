defmodule Auth0Jwks.Plug.GetUser do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(%{assigns: %{auth0_claims: claims, auth0_access_token: token}} = conn, opts) do
    user_from_claim_fn = Auth0Jwks.Config.get_opt_or_error(opts, :user_from_claim, __MODULE__)
    case user_from_claim_fn.(claims, token) do
      {:ok, current_user} ->
        assign(conn, :current_user, current_user)
      _ ->
        Auth0Jwks.Plug.Response.user_not_found(conn)
    end
  end

  def call(conn, _), do: Auth0Jwks.Plug.Response.user_not_found(conn)
end

defmodule Auth0Jwks.Plug.Response do
  import Plug.Conn
  def user_not_found(conn) do
    conn
    |> send_resp(403, "user not found")
    |> halt()
  end

  def unauthorized(conn) do
    conn
    |> send_resp(401, "unauthorized")
    |> halt()
  end
end

defmodule Auth0Jwks.Plug.ValidateToken do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> get_req_header("authorization")
    |> extract_bearer_token()
    |> handle_token(conn)
  end

  def extract_bearer_token([header | _]) do
    ~r/bearer (.+)/i
    |> Regex.scan(header)
    |> List.flatten()
    |> case do
      [_, token] -> token
      _ -> nil
    end
  end
  def extract_bearer_token(_), do: nil

  def handle_token(token, conn) do
    token
    |> Auth0Jwks.Token.verify_and_validate()
    |> case do
      {:ok, claims} ->

        conn
        |> assign(:auth0_claims, claims)
        |> assign(:auth0_access_token, token)

      _ ->
        Auth0Jwks.Plug.Response.unauthorized(conn)
    end
  end


end

defmodule Auth0Jwks.UserInfo do
  use HTTPoison.Base

  def from_token(token) do
    auth_header = {"Authorization", "Bearer #{token}"}
    with {:ok, response} <- get("userinfo", [auth_header]) do
      response
      |> Map.get(:body)
      |> Poison.decode()
    end
  end

  def process_url(path), do: Auth0Jwks.Config.iss() <> path
end

defmodule Auth0Jwks.Config do
  defmodule MissingValueError do
    defexception [:message]
  end

  defp get_config_or_error(parent, child) do
    case Application.get_env(parent, child) do
      nil ->
        raise MissingValueError, message: "Auth0 config [:#{parent}, :#{child}] is not set"
      value ->
        value
    end
  end

  def get_opt_or_error(opts, opt_to_get, parent_module) do
    case Keyword.get(opts, opt_to_get) do
      nil ->
        raise MissingValueError, message: "#{parent_module} config :#{opt_to_get} is not set"
      value ->
        value
    end
  end

  def iss, do: get_config_or_error(:auth0, :iss)
  def aud, do: get_config_or_error(:auth0, :aud)
  def jwks_url, do: iss() <> ".well-known/jwks.json"
end

defmodule Auth0Jwks.Strategy do
  use JokenJwks.DefaultStrategyTemplate
  def init_opts(opts), do: Keyword.merge(opts, jwks_url: Auth0Jwks.Config.jwks_url())
end

defmodule Auth0Jwks.Token do
  use Joken.Config, default_signer: nil

  add_hook(JokenJwks, strategy: Auth0Jwks.Strategy)

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
    |> add_claim("iss", nil, &issued_by_auth0_domain?/1) # todo create util
    |> add_claim("aud", nil, &has_auth0_custom_api_audience?/1)
  end

  def issued_by_auth0_domain?(iss), do: iss == Auth0Jwks.Config.iss()
  def has_auth0_custom_api_audience?(aud), do: validate_audience(aud, Auth0Jwks.Config.aud())

  defp validate_audience(value, audience) when is_list(value), do: Enum.any?(value, &(&1 == audience))
  defp validate_audience(value, audience), do: validate_audience([value], audience)
end
