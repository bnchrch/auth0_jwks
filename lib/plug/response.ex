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
