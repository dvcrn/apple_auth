defmodule AppleAuth.PublicKeys do
  @moduledoc """
  Caches Apple's JWKS public keys used to verify Sign in with Apple identity tokens.

  Started under `AppleAuth.Application` and eagerly fetches keys on boot.
  TTL is derived from the `Cache-Control: max-age` header returned by Apple.
  """

  use Agent

  require Logger

  @jwks_url "https://appleid.apple.com/auth/keys"
  @fallback_ttl_seconds 3600

  @type state :: %{
          keys: %{optional(String.t()) => map()},
          expires_at_s: non_neg_integer()
        }

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    Agent.start_link(fn -> init_state(opts) end, name: __MODULE__)
  end

  @spec get_for_kid(String.t()) :: {:ok, map()} | {:error, term()}
  def get_for_kid(kid) when is_binary(kid) and kid != "" do
    with {:ok, keys} <- get_keys() do
      do_get_for_kid(keys, kid)
    end
  end

  def get_for_kid(_), do: {:error, :key_not_found}

  @spec get_keys() :: {:ok, map()} | {:error, term()}
  def get_keys do
    ensure_started!()

    now_s = now_s()

    {keys, _expires_at_s} =
      Agent.get_and_update(__MODULE__, fn %{keys: keys, expires_at_s: exp} = st ->
        if exp > now_s and map_size(keys) > 0 do
          {{keys, exp}, st}
        else
          refresh_state_from_fetch(st, now_s)
        end
      end)

    if map_size(keys) > 0 do
      {:ok, keys}
    else
      {:error, :no_keys}
    end
  end

  @spec refresh_keys() :: {:ok, map()} | {:error, term()}
  def refresh_keys do
    ensure_started!()
    now_s = now_s()
    Logger.debug("apple_auth: refreshing Apple JWKS public keys")

    Agent.get_and_update(__MODULE__, fn %{keys: _keys} = st ->
      case fetch_keys() do
        {:ok, keys2, ttl_s} ->
          exp2 = now_s + ttl_s
          {{:ok, keys2}, %{st | keys: keys2, expires_at_s: exp2}}

        {:error, reason} ->
          {{:error, reason}, st}
      end
    end)
    |> case do
      {:ok, keys} -> {:ok, keys}
      {:error, reason} -> {:error, reason}
    end
  end

  # -- Private --

  defp do_get_for_kid(keys, kid) do
    case Map.get(keys, kid) do
      jwk when is_map(jwk) ->
        {:ok, jwk}

      _ ->
        refresh_and_retry_get_for_kid(kid)
    end
  end

  defp refresh_and_retry_get_for_kid(kid) do
    with {:ok, keys2} <- refresh_keys() do
      case Map.get(keys2, kid) do
        jwk when is_map(jwk) -> {:ok, jwk}
        _ -> {:error, :key_not_found}
      end
    end
  end

  defp refresh_state_from_fetch(st, now_s) do
    case fetch_keys() do
      {:ok, keys2, ttl_s} ->
        exp2 = now_s + ttl_s
        {{keys2, exp2}, %{st | keys: keys2, expires_at_s: exp2}}

      {:error, _reason} ->
        retry_exp = now_s + 60
        {{st.keys, retry_exp}, %{st | expires_at_s: retry_exp}}
    end
  end

  defp init_state(_opts) do
    Logger.debug("apple_auth: prefetching Apple JWKS public keys")

    case fetch_keys() do
      {:ok, keys, ttl_s} ->
        Logger.info(
          "apple_auth: downloaded Apple JWKS public keys count=#{map_size(keys)} ttl_seconds=#{ttl_s}"
        )

        %{keys: keys, expires_at_s: now_s() + ttl_s}

      {:error, reason} ->
        Logger.warning(
          "apple_auth: failed to download Apple JWKS public keys reason=#{inspect(reason)}"
        )

        %{keys: %{}, expires_at_s: 0}
    end
  end

  defp fetch_keys do
    Logger.debug("apple_auth: downloading public keys from #{@jwks_url}")

    case Req.get(@jwks_url, decode_body: false, redirect: true) do
      {:ok, %{status: 200, headers: headers, body: body}} ->
        with {:ok, %{"keys" => keys_list}} <- Jason.decode(to_binary(body)) do
          keys_map =
            keys_list
            |> Enum.filter(&is_map/1)
            |> Map.new(fn %{"kid" => kid} = jwk -> {kid, jwk} end)

          ttl_s = cache_max_age_seconds(headers) || @fallback_ttl_seconds
          {:ok, keys_map, ttl_s}
        end

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, to_binary(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp cache_max_age_seconds(headers) do
    Enum.find_value(headers, fn {k, v} ->
      key = k |> to_string() |> String.downcase()
      if key == "cache-control", do: parse_max_age(v), else: nil
    end)
  end

  defp parse_max_age(v) do
    v =
      cond do
        is_binary(v) -> v
        is_list(v) and Enum.all?(v, &is_binary/1) -> Enum.join(v, ", ")
        true -> to_string(v)
      end

    case Regex.run(~r/max-age=(\d+)/, v) do
      [_, digits] ->
        case Integer.parse(digits) do
          {n, _} when n > 0 -> n
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp ensure_started! do
    case Process.whereis(__MODULE__) do
      nil ->
        raise "AppleAuth.PublicKeys is not started (start the :apple_auth application)"

      _pid ->
        :ok
    end
  end

  defp now_s, do: System.system_time(:second)

  defp to_binary(data) when is_binary(data), do: data
  defp to_binary(data), do: IO.iodata_to_binary(data)
end
