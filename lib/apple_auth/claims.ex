defmodule AppleAuth.Claims do
  @moduledoc """
  Struct representing validated Apple ID token claims.
  """

  @type t :: %__MODULE__{
          iss: String.t() | nil,
          sub: String.t() | nil,
          aud: String.t() | nil,
          exp: integer() | nil,
          iat: integer() | nil,
          email: String.t() | nil,
          email_verified: boolean() | String.t() | nil,
          is_private_email: boolean() | String.t() | nil,
          nonce: String.t() | nil,
          auth_time: integer() | nil,
          raw_claims: map()
        }

  defstruct [
    :iss,
    :sub,
    :aud,
    :exp,
    :iat,
    :email,
    :email_verified,
    :is_private_email,
    :nonce,
    :auth_time,
    :raw_claims
  ]

  @spec new(map()) :: t()
  def new(claims) when is_map(claims) do
    %__MODULE__{
      iss: claims["iss"],
      sub: claims["sub"],
      aud: claims["aud"],
      exp: claims["exp"],
      iat: claims["iat"],
      email: claims["email"],
      email_verified: claims["email_verified"],
      is_private_email: claims["is_private_email"],
      nonce: claims["nonce"],
      auth_time: claims["auth_time"],
      raw_claims: claims
    }
  end
end
