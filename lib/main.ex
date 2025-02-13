defmodule Redis.CLI do
  @moduledoc """
  The CLI for the implementation of a Redis server.
  """

  def main(_args) do
    # Start the Server application
    {:ok, _pid} = Application.ensure_all_started(:redis)

    # Run forever
    Process.sleep(:infinity)
  end
end
