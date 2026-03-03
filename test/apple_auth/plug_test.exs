defmodule AppleAuth.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn
  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:apple_auth, :token_validator_adapter, AppleAuth.TokenValidatorMock)
    on_exit(fn -> Application.delete_env(:apple_auth, :token_validator_adapter) end)
    :ok
  end

  describe "call/2 with default options" do
    test "assigns nil when no authorization header present" do
      conn =
        conn(:get, "/")
        |> AppleAuth.Plug.call(AppleAuth.Plug.init([]))

      assert conn.assigns[:apple_auth] == nil
      refute conn.halted
    end

    test "assigns claims on valid token" do
      claims = AppleAuth.Claims.new(%{"sub" => "user123", "iss" => "https://appleid.apple.com"})

      AppleAuth.TokenValidatorMock
      |> expect(:validate_id_token, fn "valid-token", _opts -> {:ok, claims} end)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer valid-token")
        |> AppleAuth.Plug.call(AppleAuth.Plug.init([]))

      assert conn.assigns[:apple_auth] == claims
      refute conn.halted
    end

    test "ignores invalid token by default" do
      AppleAuth.TokenValidatorMock
      |> expect(:validate_id_token, fn "bad-token", _opts -> {:error, :invalid_signature} end)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer bad-token")
        |> AppleAuth.Plug.call(AppleAuth.Plug.init([]))

      assert conn.assigns[:apple_auth] == nil
      refute conn.halted
    end
  end

  describe "call/2 with on_invalid_token: :unauthorized" do
    test "sends 401 on invalid token" do
      AppleAuth.TokenValidatorMock
      |> expect(:validate_id_token, fn "bad-token", _opts -> {:error, :invalid_signature} end)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer bad-token")
        |> AppleAuth.Plug.call(AppleAuth.Plug.init(on_invalid_token: :unauthorized))

      assert conn.status == 401
      assert conn.halted
      assert get_resp_header(conn, "www-authenticate") == ["Bearer realm=\"apple\""]
    end
  end

  describe "call/2 with on_invalid_token: {:assign_error, key}" do
    test "assigns error reason to specified key" do
      AppleAuth.TokenValidatorMock
      |> expect(:validate_id_token, fn "bad-token", _opts -> {:error, :token_expired} end)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer bad-token")
        |> AppleAuth.Plug.call(
          AppleAuth.Plug.init(on_invalid_token: {:assign_error, :auth_error})
        )

      assert conn.assigns[:auth_error] == :token_expired
      refute conn.halted
    end
  end
end
