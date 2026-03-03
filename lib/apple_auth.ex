defmodule AppleAuth do
  @moduledoc """
  Apple Sign in with Apple (SIWA) authentication library.

  Provides two core functions:
  - `validate_id_token/2` — validate an Apple identity token against Apple's JWKS public keys
  - `exchange_authorization_code/2` — exchange an authorization code for tokens via Apple's token endpoint
  """

  @type id_token :: String.t()
  @type authorization_code :: String.t()
  @type opts :: keyword()

  @spec validate_id_token(id_token(), opts()) :: {:ok, AppleAuth.Claims.t()} | {:error, term()}
  def validate_id_token(token, opts \\ []) when is_binary(token) and is_list(opts) do
    AppleAuth.TokenValidator.validate_id_token(token, opts)
  end

  @spec exchange_authorization_code(authorization_code(), opts()) ::
          {:ok, AppleAuth.TokenResponse.t()} | {:error, term()}
  def exchange_authorization_code(code, opts \\ []) when is_binary(code) and is_list(opts) do
    AppleAuth.TokenExchanger.exchange_authorization_code(code, opts)
  end
end
