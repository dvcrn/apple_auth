defmodule AppleAuth.TokenExchanger do
  @moduledoc """
  Token exchanger adapter interface for exchanging Apple authorization codes for tokens.

  Configure via:

      config :apple_auth, :token_exchanger_adapter, AppleAuth.TokenExchanger.Apple
  """

  @type authorization_code :: String.t()
  @type opts :: keyword()

  @callback exchange_authorization_code(authorization_code(), opts()) ::
              {:ok, AppleAuth.TokenResponse.t()} | {:error, term()}

  @spec exchange_authorization_code(authorization_code(), opts()) ::
          {:ok, AppleAuth.TokenResponse.t()} | {:error, term()}
  def exchange_authorization_code(code, opts \\ []) when is_binary(code) and is_list(opts) do
    adapter().exchange_authorization_code(code, opts)
  end

  defp adapter do
    Application.get_env(
      :apple_auth,
      :token_exchanger_adapter,
      AppleAuth.TokenExchanger.Apple
    )
  end
end
