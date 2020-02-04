defmodule Auth0Jwks.Strategy do
  use JokenJwks.DefaultStrategyTemplate
  def init_opts(opts), do: Keyword.merge(opts, jwks_url: Auth0Jwks.Config.jwks_url())
end
