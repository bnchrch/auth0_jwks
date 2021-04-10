defmodule Auth0Jwks.UserInfo do
  use HTTPoison.Base

  alias Auth0Jwks.Config

  def from_token(token) do
    auth_header = {"Authorization", "Bearer #{token}"}

    with {:ok, response} <- get("userinfo", [auth_header]) do
      response
      |> Map.get(:body)
      |> Config.json_library().decode()
    end
  end

  def process_url(path), do: Auth0Jwks.Config.iss() <> path
  def process_request_options(opts), do: opts ++ [timeout: Auth0Jwks.Config.timeout(), recv_timeout: Auth0Jwks.Config.timeout()]

end
