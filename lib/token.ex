defmodule Auth0Jwks.Token do
  use Joken.Config, default_signer: nil

  add_hook(JokenJwks, strategy: Auth0Jwks.Strategy)

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
    # todo create util
    |> add_claim("iss", nil, &issued_by_auth0_domain?/1)
    |> add_claim("aud", nil, &has_auth0_custom_api_audience?/1)
  end

  def issued_by_auth0_domain?(iss), do: iss == Auth0Jwks.Config.iss()
  def has_auth0_custom_api_audience?(aud), do: validate_audience(aud, Auth0Jwks.Config.aud())

  defp validate_audience(value, audience) when is_list(value),
    do: Enum.any?(value, &(&1 == audience))

  defp validate_audience(value, audience), do: validate_audience([value], audience)
end
