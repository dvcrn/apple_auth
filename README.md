# AppleAuth

Elixir library for Apple Sign in with Apple (SIWA) authentication. Validates Apple identity tokens against Apple's JWKS public keys and exchanges authorization codes for tokens.

## Installation

Add `apple_auth` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:apple_auth, "~> 0.1.0"}          
  ]
end
```

## Configuration

```elixir
# config/runtime.exs or config/config.exs
config :apple_auth,
  bundle_id: System.get_env("APPLE_BUNDLE_ID") || "com.example.app",
  team_id: "YOUR_TEAM_ID",
  key_id: "YOUR_KEY_ID",
  client_secret_pem: System.get_env("APPLE_CLIENT_SECRET_PEM")  # ES256 private key
```

| Key                 | Env var                   | Required for     |
| ------------------- | ------------------------- | ---------------- |
| `bundle_id`         | `APPLE_BUNDLE_ID`         | Token validation |
| `team_id`           | `APPLE_TEAM_ID`           | Code exchange    |
| `key_id`            | `APPLE_KEY_ID`            | Code exchange    |
| `client_secret_pem` | `APPLE_CLIENT_SECRET_PEM` | Code exchange    |

Config resolution order: **opts keyword > Application env > System env var**.

## Usage

### Validate an identity token

```elixir
case AppleAuth.validate_id_token(token) do
  {:ok, %AppleAuth.Claims{sub: user_id, email: email}} ->
    # user_id is the stable Apple user identifier
    {:ok, user_id}

  {:error, reason} ->
    {:error, reason}
end
```

### Exchange an authorization code for tokens

```elixir
case AppleAuth.exchange_authorization_code(authorization_code) do
  {:ok, %{id_token: id_token, access_token: access_token, refresh_token: refresh_token}} ->
    # Validate the id_token next
    AppleAuth.validate_id_token(id_token)

  {:error, reason} ->
    {:error, reason}
end
```

### Phoenix Plug

Protect routes by adding the plug to your pipeline:

```elixir
# In your router
pipeline :apple_authenticated do
  plug AppleAuth.Plug, on_invalid_token: :unauthorized
end

scope "/api" do
  pipe_through [:api, :apple_authenticated]
  # ...
end
```

The plug extracts the Bearer token from the `Authorization` header, validates it, and assigns the result to `conn.assigns.apple_auth`.

Options for `on_invalid_token`:

- `:ignore` (default) — pass through, assigns remain `nil`
- `:unauthorized` — send 401 and halt
- `{:assign_error, key}` — assign the error to `conn.assigns[key]`

Access claims in your controller:

```elixir
def index(conn, _params) do
  %AppleAuth.Claims{sub: user_id} = conn.assigns.apple_auth
  # ...
end
```

## License

MIT
