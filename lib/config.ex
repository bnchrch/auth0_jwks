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

  def iss, do: get_config_or_error(:auth0_jwks, :iss)
  def aud, do: get_config_or_error(:auth0_jwks, :aud)
  def jwks_url, do: iss() <> ".well-known/jwks.json"

  def json_library, do: Application.get_env(:auth0_jwks, :json_library) || Poison
  def timeout, do: Application.get_env(:auth0_jwks, :timeout) || 50_000
end
