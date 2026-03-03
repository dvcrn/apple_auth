defmodule AppleAuth.ClaimsTest do
  use ExUnit.Case, async: true

  alias AppleAuth.Claims

  test "new/1 maps raw claims to struct fields" do
    raw = %{
      "iss" => "https://appleid.apple.com",
      "sub" => "001234.abcdef",
      "aud" => "com.test.app",
      "exp" => 1_700_000_000,
      "iat" => 1_699_990_000,
      "email" => "user@privaterelay.appleid.com",
      "email_verified" => "true",
      "is_private_email" => "true",
      "nonce" => "abc123",
      "auth_time" => 1_699_990_000
    }

    claims = Claims.new(raw)

    assert claims.iss == "https://appleid.apple.com"
    assert claims.sub == "001234.abcdef"
    assert claims.aud == "com.test.app"
    assert claims.exp == 1_700_000_000
    assert claims.iat == 1_699_990_000
    assert claims.email == "user@privaterelay.appleid.com"
    assert claims.email_verified == "true"
    assert claims.is_private_email == "true"
    assert claims.nonce == "abc123"
    assert claims.auth_time == 1_699_990_000
    assert claims.raw_claims == raw
  end

  test "new/1 handles missing optional fields" do
    raw = %{"iss" => "https://appleid.apple.com", "sub" => "001234"}
    claims = Claims.new(raw)

    assert claims.iss == "https://appleid.apple.com"
    assert claims.sub == "001234"
    assert claims.email == nil
    assert claims.nonce == nil
    assert claims.raw_claims == raw
  end
end
