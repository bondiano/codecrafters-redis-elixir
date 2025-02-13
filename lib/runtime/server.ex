defmodule Redis.Runtime.Server do
  @moduledoc """
  The Server application.
  """

  use Application
  require Logger
  alias Redis.Impl.Command

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    loop_accept(socket)
  end

  def loop_accept(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        pid = spawn_link(fn -> serve(client) end)
        :ok = :gen_tcp.controlling_process(client, pid)
        loop_accept(socket)

      {:error, :closed} ->
        Logger.info("Connection closed")
        :gen_tcp.close(socket)

      {:error, _reason} ->
        Logger.error("Error accepting connection")
        :gen_tcp.close(socket)
    end
  end

  def serve(client) do
    case read_request(client) do
      {:ok, request} ->
        request |> Command.parse() |> Command.exec() |> write_response(client)
        serve(client)

      error ->
        error
    end
  end

  def read_request(client) do
    :gen_tcp.recv(client, 0)
  end

  def write_response(response, client) do
    :ok = :gen_tcp.send(client, response)
  end
end
