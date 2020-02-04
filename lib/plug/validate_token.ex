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
