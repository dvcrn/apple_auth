defmodule AppleAuth.PemJwkHelper do
  @moduledoc """
  Helper to convert an EC PEM key to a JWK map at runtime.
  """

  @doc """
  Converts a PEM string or reads a PEM file from disk and returns a JWK map suitable for Joken.

  ## Parameters
    - pem: PEM string or path to PEM file (string)
    - opts: Keyword list. If opts[:from_file] is true, treat pem as a file path. Default: false.

  ## Returns
    - JWK map (for ES256/Apple keys)
  """
  @spec pem_to_jwk_map(String.t(), keyword()) :: map()
  def pem_to_jwk_map(pem, opts \\ []) when is_binary(pem) do
    pem_data =
      if Keyword.get(opts, :from_file, false) do
        File.read!(pem)
      else
        pem
      end

    jwk = JOSE.JWK.from_pem(pem_data)
    jwk |> JOSE.JWK.to_map() |> elem(1)
  end
end
