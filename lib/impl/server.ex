defmodule Redis.Impl.Server do
  @moduledoc false

  require Logger
  alias Redis.Impl.Command
  alias Redis.Runtime.Config
  alias Redis.Impl.Protocol

  @doc """
  Listen for incoming connections
  """
  def listen() do
    port = Config.get(:port)
    replicaof = Config.get(:replicaof)

    if replicaof do
      setup_replica(replicaof)
    end

    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
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
    case :gen_tcp.send(client, response) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Error writing response: #{reason}")
        :gen_tcp.close(client)
    end
  end

  defp setup_replica(replicaof) do
    [host, port] = String.split(replicaof, " ")

    case :gen_tcp.connect(String.to_charlist(host), String.to_integer(port), [
           :binary,
           active: false
         ]) do
      {:ok, socket} ->
        :gen_tcp.send(socket, Protocol.encode_list(["PING"]))

        with {:ok, _} <- :gen_tcp.recv(socket, 0),
             :ok <-
               :gen_tcp.send(
                 socket,
                 Protocol.encode_list([
                   "REPLCONF",
                   "listening-port",
                   Integer.to_string(Config.get(:port))
                 ])
               ),
             {:ok, _} <- :gen_tcp.recv(socket, 0),
             :ok <-
               :gen_tcp.send(
                 socket,
                 Protocol.encode_list(["REPLCONF", "capa", "psync2"])
               ),
             {:ok, _} <- :gen_tcp.recv(socket, 0) do
          :gen_tcp.close(socket)
          Logger.info("Connected to master: #{replicaof}")
        end

      {:error, reason} ->
        Logger.error("Error connecting to master: #{reason}")
    end
  end
end
