defmodule Auth0Jwks.Plug.Response do
  import Plug.Conn

  def user_not_found(conn, opts) do
    if Keyword.get(opts, :no_halt, false) do
      conn
    else
      conn
      |> send_resp(403, "user not found")
      |> halt()
    end
  end

  def unauthorized(conn, opts) do
    if Keyword.get(opts, :no_halt, false) do
      conn
    else
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    end
  end
end
