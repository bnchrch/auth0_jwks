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
