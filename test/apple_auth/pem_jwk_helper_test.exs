defmodule AppleAuth.PemJwkHelperTest do
  use ExUnit.Case, async: true

  alias AppleAuth.PemJwkHelper

  # A valid EC P-256 private key in PKCS#8 PEM format for testing
  @test_ec_pem """
  -----BEGIN PRIVATE KEY-----
  MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg8C68cSqxqkbwPO8i
  V2kkW8RJaw7KECSJYzdKjXcADa2hRANCAAQAWFpSvjMKBOEoVzULvJpU1hLWSUzz
  Jc/I9JL300bYrMOIBQB4uWpc0CgwrijYQikgkdtG4rIGtCQQP2mOxrym
  -----END PRIVATE KEY-----
  """

  test "pem_to_jwk_map converts a PEM string to a JWK map" do
    result = PemJwkHelper.pem_to_jwk_map(@test_ec_pem)

    assert is_map(result)
    assert Map.has_key?(result, "kty")
  end

  test "pem_to_jwk_map reads from file when from_file: true" do
    path = Path.join(System.tmp_dir!(), "apple_auth_test_key.pem")
    File.write!(path, @test_ec_pem)
    on_exit(fn -> File.rm(path) end)

    result = PemJwkHelper.pem_to_jwk_map(path, from_file: true)

    assert is_map(result)
    assert Map.has_key?(result, "kty")
  end
end
