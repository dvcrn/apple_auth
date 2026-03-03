defmodule AppleAuth.TokenExchanger.Apple do
  @moduledoc """
  Exchanges an Apple authorization code for tokens via Apple's token endpoint.
  """

  @behaviour AppleAuth.TokenExchanger

  require Logger

  alias AppleAuth.Config
  alias AppleAuth.PemJwkHelper

  @apple_token_url "https://appleid.apple.com/auth/token"

  @impl true
  @spec exchange_authorization_code(String.t(), keyword()) ::
          {:ok, AppleAuth.TokenResponse.t()} | {:error, term()}
  def exchange_authorization_code(code, opts \\ []) when is_binary(code) and is_list(opts) do
    with {:ok, client_secret_pem} <- require_config(:client_secret_pem, opts),
         {:ok, team_id} <- require_config(:team_id, opts),
         {:ok, key_id} <- require_config(:key_id, opts),
         {:ok, bundle_id} <- require_config(:bundle_id, opts),
         {:ok, signed_secret} <-
           build_client_secret(client_secret_pem, team_id, key_id, bundle_id) do
      send_token_request(bundle_id, signed_secret, code)
    end
  end

  defp require_config(:client_secret_pem, opts) do
    case Config.client_secret_pem(opts) do
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, :missing_client_secret_pem}
    end
  end

  defp require_config(:team_id, opts) do
    case Config.team_id(opts) do
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, :missing_team_id}
    end
  end

  defp require_config(:key_id, opts) do
    case Config.key_id(opts) do
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, :missing_key_id}
    end
  end

  defp require_config(:bundle_id, opts) do
    case Config.bundle_id(opts) do
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, :missing_bundle_id}
    end
  end

  defp build_client_secret(pem, team_id, key_id, bundle_id) do
    now = System.system_time(:second)
    jwk_map = PemJwkHelper.pem_to_jwk_map(pem)
    header = %{"alg" => "ES256", "kid" => key_id}
    signer = Joken.Signer.create("ES256", jwk_map, header)

    claims = %{
      "iss" => team_id,
      "iat" => now,
      "exp" => now + 3600,
      "aud" => "https://appleid.apple.com",
      "sub" => bundle_id
    }

    case Joken.Signer.sign(claims, signer) do
      {:ok, signed} -> {:ok, signed}
      {:error, reason} -> {:error, {:signing_failed, reason}}
    end
  rescue
    e -> {:error, {:signing_error, e}}
  end

  defp send_token_request(client_id, client_secret, code) do
    form_body =
      URI.encode_query(%{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "code" => code,
        "grant_type" => "authorization_code"
      })

    headers = [
      {"content-type", "application/x-www-form-urlencoded"},
      {"accept", "application/json"}
    ]

    case Req.post(@apple_token_url, body: form_body, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_token_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, {:exchange_failed, status, body}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp parse_token_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> parse_token_response(decoded)
      {:error, _} -> {:error, :invalid_response_json}
    end
  end

  defp parse_token_response(decoded) when is_map(decoded) do
    case Map.get(decoded, "id_token") do
      nil ->
        {:error, :missing_id_token}

      _id_token ->
        {:ok,
         %AppleAuth.TokenResponse{
           access_token: Map.get(decoded, "access_token"),
           token_type: Map.get(decoded, "token_type"),
           expires_in: Map.get(decoded, "expires_in"),
           refresh_token: Map.get(decoded, "refresh_token"),
           id_token: Map.get(decoded, "id_token")
         }}
    end
  end
end
