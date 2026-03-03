defmodule AppleAuth.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {AppleAuth.PublicKeys, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AppleAuth.Supervisor)
  end
end
