defmodule Redis.Runtime.Application do
  @moduledoc false

  use Application

  @spec start(term(), term()) :: {:ok, pid()}
  def start(_type, _args) do
    children = [
      {Redis.Runtime.Config, name: Redis.Runtime.Config},
      {Redis.Runtime.Storage, name: Redis.Runtime.Storage},
      Supervisor.child_spec({Task, fn -> Redis.Impl.Server.listen() end}, restart: :permanent)
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Redis.Runtime.Supervisor,
      max_restarts: 5
    )
  end
end
