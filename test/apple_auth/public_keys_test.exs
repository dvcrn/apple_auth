defmodule AppleAuth.PublicKeysTest do
  use ExUnit.Case

  alias AppleAuth.PublicKeys

  describe "get_for_kid/1" do
    test "returns key when present in cache" do
      keys_map = %{
        "test-kid-1" => %{"kty" => "RSA", "kid" => "test-kid-1", "n" => "abc", "e" => "AQAB"},
        "test-kid-2" => %{"kty" => "RSA", "kid" => "test-kid-2", "n" => "def", "e" => "AQAB"}
      }

      # Directly update the agent state with test keys
      Agent.update(PublicKeys, fn _st ->
        %{keys: keys_map, expires_at_s: System.system_time(:second) + 3600}
      end)

      assert {:ok, %{"kid" => "test-kid-1"}} = PublicKeys.get_for_kid("test-kid-1")
      assert {:ok, %{"kid" => "test-kid-2"}} = PublicKeys.get_for_kid("test-kid-2")
    end

    test "returns error for empty kid" do
      assert {:error, :key_not_found} = PublicKeys.get_for_kid("")
      assert {:error, :key_not_found} = PublicKeys.get_for_kid(nil)
    end
  end

  describe "get_keys/0" do
    test "returns cached keys when not expired" do
      keys_map = %{"kid1" => %{"kty" => "RSA"}}

      Agent.update(PublicKeys, fn _st ->
        %{keys: keys_map, expires_at_s: System.system_time(:second) + 3600}
      end)

      assert {:ok, ^keys_map} = PublicKeys.get_keys()
    end
  end
end
