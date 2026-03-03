defmodule AppleAuth.TokenExchanger.AppleTest do
  use ExUnit.Case, async: true

  alias AppleAuth.TokenExchanger.Apple, as: Exchanger

  describe "exchange_authorization_code/2" do
    test "returns error when client_secret_pem is missing" do
      opts = [team_id: "TEAM", key_id: "KEY", bundle_id: "com.test"]

      assert {:error, :missing_client_secret_pem} =
               Exchanger.exchange_authorization_code("code", opts)
    end

    test "returns error when team_id is missing" do
      opts = [client_secret_pem: "pem", key_id: "KEY", bundle_id: "com.test"]
      assert {:error, :missing_team_id} = Exchanger.exchange_authorization_code("code", opts)
    end

    test "returns error when key_id is missing" do
      opts = [client_secret_pem: "pem", team_id: "TEAM", bundle_id: "com.test"]
      assert {:error, :missing_key_id} = Exchanger.exchange_authorization_code("code", opts)
    end

    test "returns error when bundle_id is missing" do
      # Temporarily clear any app-level bundle_id config
      old = Application.get_env(:apple_auth, :bundle_id)
      Application.delete_env(:apple_auth, :bundle_id)
      on_exit(fn -> if old, do: Application.put_env(:apple_auth, :bundle_id, old) end)

      opts = [client_secret_pem: "pem", team_id: "TEAM", key_id: "KEY"]
      assert {:error, :missing_bundle_id} = Exchanger.exchange_authorization_code("code", opts)
    end
  end
end
