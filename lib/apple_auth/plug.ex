defmodule AppleAuth.Plug do
  @moduledoc """
  A Plug that verifies Apple Sign in with Apple identity tokens.

  Extracts a Bearer token from the `Authorization` header, validates it
  against Apple's JWKS public keys, and assigns the result to `conn.assigns.apple_auth`.

  ## Usage

      # In your Phoenix router pipeline:
      plug AppleAuth.Plug

      # Return 401 on invalid/missing token:
      plug AppleAuth.Plug, on_invalid_token: :unauthorized

  ## Options

    * `:on_invalid_token` — what to do when the token is missing or invalid:
      - `:ignore` (default) — pass through, assigns remain `nil`
      - `:unauthorized` — send 401 and halt
      - `{:assign_error, key}` — assign the error reason to `conn.assigns[key]`
  """

  @behaviour Plug

  import Plug.Conn

  @assigns_key :apple_auth

  @impl true
  @spec init(keyword()) :: keyword()
  def init(opts) do
    Keyword.put_new(opts, :on_invalid_token, :ignore)
  end

  @impl true
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    conn = init_assigns(conn)

    case extract_bearer_token(conn) do
      nil ->
        conn

      token ->
        verify_and_assign(conn, token, opts)
    end
  end

  defp init_assigns(conn) do
    case conn.assigns do
      %{apple_auth: _} -> conn
      _ -> assign(conn, @assigns_key, nil)
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> token
      ["bearer " <> token | _] -> token
      _ -> nil
    end
  end

  defp verify_and_assign(conn, token, opts) do
    case AppleAuth.validate_id_token(token) do
      {:ok, claims} ->
        assign(conn, @assigns_key, claims)

      {:error, reason} ->
        handle_invalid_token(conn, reason, opts)
    end
  end

  defp handle_invalid_token(conn, reason, opts) do
    case Keyword.fetch!(opts, :on_invalid_token) do
      :ignore ->
        conn

      :unauthorized ->
        conn
        |> put_resp_header("www-authenticate", "Bearer realm=\"apple\"")
        |> send_resp(401, "Unauthorized")
        |> halt()

      {:assign_error, key} ->
        assign(conn, key, reason)
    end
  end
end
