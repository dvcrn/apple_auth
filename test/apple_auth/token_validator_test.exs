defmodule AppleAuth.TokenValidator.AppleTest do
  use ExUnit.Case, async: true

  alias AppleAuth.TokenValidator.Apple, as: Validator

  describe "validate_id_token/2" do
    test "rejects non-JWT format" do
      assert {:error, :invalid_token_format} = Validator.validate_id_token("not-a-jwt")
    end

    test "rejects empty string" do
      assert {:error, :invalid_token_format} = Validator.validate_id_token("")
    end

    test "rejects token with wrong number of parts" do
      assert {:error, :invalid_token_format} = Validator.validate_id_token("a.b")
      assert {:error, :invalid_token_format} = Validator.validate_id_token("a.b.c.d")
    end
  end
end
