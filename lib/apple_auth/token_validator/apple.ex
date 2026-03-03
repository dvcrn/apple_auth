defmodule AppleAuth.TokenValidator.Apple do
  @moduledoc """
  Validates Apple Sign in with Apple identity tokens against Apple's JWKS public keys.
  """

  @behaviour AppleAuth.TokenValidator

  alias AppleAuth.Claims
  alias AppleAuth.Config
  alias AppleAuth.PublicKeys

  @apple_issuer "https://appleid.apple.com"

  @impl true
  @spec validate_id_token(String.t(), keyword()) :: {:ok, Claims.t()} | {:error, term()}
  def validate_id_token(token, opts \\ []) when is_binary(token) and is_list(opts) do
    if looks_like_jwt?(token) do
      do_validate(token, opts)
    else
      {:error, :invalid_token_format}
    end
  end

  defp do_validate(token, opts) do
    with {:ok, header} <- peek_header(token),
         :ok <- validate_header(header),
         {:ok, kid} <- fetch_kid(header),
         {:ok, jwk_map} <- PublicKeys.get_for_kid(kid),
         {:ok, raw_claims} <- verify_with_jwk(token, jwk_map),
         :ok <- validate_claims(raw_claims, opts) do
      {:ok, Claims.new(raw_claims)}
    end
  end

  defp peek_header(token) do
    token |> JOSE.JWS.peek_protected() |> Jason.decode()
  rescue
    _ -> {:error, :invalid_token}
  end

  defp validate_header(%{"alg" => "RS256"}), do: :ok
  defp validate_header(%{"alg" => _}), do: {:error, :invalid_alg}
  defp validate_header(_), do: {:error, :invalid_header}

  defp fetch_kid(%{"kid" => kid}) when is_binary(kid) and kid != "", do: {:ok, kid}
  defp fetch_kid(_), do: {:error, :no_kid}

  defp verify_with_jwk(token, jwk_map) do
    jwk = JOSE.JWK.from_map(jwk_map)

    case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
      {true, jwt, _jws} ->
        {_fields, claims} = JOSE.JWT.to_map(jwt)
        {:ok, claims}

      {false, _jwt, _jws} ->
        {:error, :invalid_signature}
    end
  rescue
    e in [ArgumentError, ErlangError] -> {:error, {:exception, e}}
  catch
    :exit, reason -> {:error, {:exit, reason}}
  end

  defp validate_claims(claims, opts) do
    now = System.system_time(:second)
    bundle_id = Config.bundle_id(opts)

    with :ok <- require_iss(claims),
         :ok <- require_aud(claims, bundle_id),
         :ok <- require_sub(claims),
         :ok <- require_exp_future(claims, now),
         :ok <- require_iat_past(claims, now) do
      :ok
    end
  end

  defp require_iss(%{"iss" => @apple_issuer}), do: :ok
  defp require_iss(_), do: {:error, :invalid_issuer}

  defp require_aud(%{"aud" => aud}, bundle_id) when is_binary(bundle_id) and aud == bundle_id,
    do: :ok

  defp require_aud(_, nil), do: {:error, :missing_bundle_id}
  defp require_aud(_, _), do: {:error, :invalid_audience}

  defp require_sub(%{"sub" => sub}) when is_binary(sub) and sub != "", do: :ok
  defp require_sub(_), do: {:error, :invalid_sub}

  defp require_exp_future(%{"exp" => exp}, now) when is_number(exp) and exp > now, do: :ok
  defp require_exp_future(_, _), do: {:error, :token_expired}

  defp require_iat_past(%{"iat" => iat}, now) when is_number(iat) and iat <= now, do: :ok
  defp require_iat_past(_, _), do: {:error, :invalid_iat}

  defp looks_like_jwt?(token) when is_binary(token) do
    length(String.split(token, ".", parts: 4)) == 3
  end
end
