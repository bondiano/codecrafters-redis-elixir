defmodule Redis.Runtime.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task, fn -> Redis.Impl.Server.listen() end}, restart: :permanent),
      {Redis.Runtime.Storage, name: Redis.Runtime.Storage},
      {Redis.Runtime.Config, name: Redis.Runtime.Config}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Redis.Runtime.Supervisor,
      max_restarts: 5
    )
  end
end
