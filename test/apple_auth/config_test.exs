defmodule AppleAuth.ConfigTest do
  use ExUnit.Case, async: true

  alias AppleAuth.Config

  describe "bundle_id/1" do
    test "returns value from opts first" do
      assert Config.bundle_id(bundle_id: "com.test.app") == "com.test.app"
    end

    test "falls back to application env" do
      Application.put_env(:apple_auth, :bundle_id, "com.env.app")
      on_exit(fn -> Application.delete_env(:apple_auth, :bundle_id) end)

      assert Config.bundle_id([]) == "com.env.app"
    end

    test "opts take precedence over application env" do
      Application.put_env(:apple_auth, :bundle_id, "com.env.app")
      on_exit(fn -> Application.delete_env(:apple_auth, :bundle_id) end)

      assert Config.bundle_id(bundle_id: "com.opts.app") == "com.opts.app"
    end

    test "returns nil when nothing configured" do
      Application.delete_env(:apple_auth, :bundle_id)
      assert Config.bundle_id([]) == nil
    end
  end

  describe "team_id/1" do
    test "returns value from opts" do
      assert Config.team_id(team_id: "TEAM123") == "TEAM123"
    end
  end

  describe "key_id/1" do
    test "returns value from opts" do
      assert Config.key_id(key_id: "KEY456") == "KEY456"
    end
  end

  describe "client_secret_pem/1" do
    test "returns value from opts" do
      assert Config.client_secret_pem(client_secret_pem: "-----BEGIN PRIVATE KEY-----") ==
               "-----BEGIN PRIVATE KEY-----"
    end
  end
end
