defmodule AppleAuth.Config do
  @moduledoc false

  @spec bundle_id(keyword()) :: String.t() | nil
  def bundle_id(opts \\ []) when is_list(opts) do
    resolve(opts, :bundle_id, "APPLE_BUNDLE_ID")
  end

  @spec team_id(keyword()) :: String.t() | nil
  def team_id(opts \\ []) when is_list(opts) do
    resolve(opts, :team_id, "APPLE_TEAM_ID")
  end

  @spec key_id(keyword()) :: String.t() | nil
  def key_id(opts \\ []) when is_list(opts) do
    resolve(opts, :key_id, "APPLE_KEY_ID")
  end

  @spec client_secret_pem(keyword()) :: String.t() | nil
  def client_secret_pem(opts \\ []) when is_list(opts) do
    resolve(opts, :client_secret_pem, "APPLE_CLIENT_SECRET_PEM")
  end

  defp resolve(opts, key, env_var) do
    case Keyword.get(opts, key) do
      val when is_binary(val) and val != "" ->
        val

      _ ->
        case Application.get_env(:apple_auth, key) do
          val when is_binary(val) and val != "" -> val
          _ -> System.get_env(env_var)
        end
    end
  end
end
