defmodule AppleAuth.TokenResponse do
  @moduledoc """
  Struct representing Apple's token endpoint response.
  """

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          token_type: String.t() | nil,
          expires_in: integer() | nil,
          refresh_token: String.t() | nil,
          id_token: String.t() | nil
        }

  defstruct [:access_token, :token_type, :expires_in, :refresh_token, :id_token]
end
