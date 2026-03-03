defmodule AppleAuth.TokenValidator do
  @moduledoc """
  Token validator adapter interface.

  Configure via:

      config :apple_auth, :token_validator_adapter, AppleAuth.TokenValidator.Apple
  """

  @type id_token :: String.t()
  @type claims :: AppleAuth.Claims.t()
  @type opts :: keyword()

  @callback validate_id_token(id_token(), opts()) :: {:ok, claims()} | {:error, term()}

  @spec validate_id_token(id_token(), opts()) :: {:ok, claims()} | {:error, term()}
  def validate_id_token(token, opts \\ []) when is_binary(token) and is_list(opts) do
    adapter().validate_id_token(token, opts)
  end

  defp adapter do
    Application.get_env(:apple_auth, :token_validator_adapter, AppleAuth.TokenValidator.Apple)
  end
end
