defmodule Redis.Impl.Command do
  @moduledoc """
  The Redis handler.
  """

  defstruct command: "", arguments: []

  alias Redis.Runtime.Storage
  alias Redis.Runtime.Config
  alias Redis.Impl.Protocol

  @type t :: %__MODULE__{
          command: String.t(),
          arguments: list()
        }

  @doc """
  Parses request to command and arguments.
  """
  @spec parse(String.t()) :: t()
  def parse(request) do
    {:ok, [command | arguments]} = Protocol.decode(request)

    %__MODULE__{command: command |> String.upcase(), arguments: arguments}
  end

  @spec exec(t()) :: String.t()
  def exec(%__MODULE__{command: "PING"}) do
    Protocol.encode("PONG")
  end

  def exec(%__MODULE__{command: "ECHO", arguments: arguments}) do
    echo = Enum.join(arguments, " ")
    len = String.length(echo)
    "$#{len}\r\n#{echo}\r\n"
  end

  def exec(%__MODULE__{command: "SET", arguments: arguments}) do
    parsed_arguments =
      Enum.chunk_by(arguments, fn arg -> String.downcase(arg) == "px" end)

    case parsed_arguments do
      [[key | values], _, [expiration]] ->
        Storage.set(key, values |> Enum.join(" "), expiration |> String.to_integer())

      [[key | values]] ->
        Storage.set(key, values |> Enum.join(" "))
    end

    Protocol.encode("OK")
  end

  def exec(%__MODULE__{command: "GET", arguments: arguments}) do
    [key] = arguments

    case Storage.get(key) do
      {:ok, value} -> Protocol.encode(value)
      {:error, _} -> Protocol.null()
    end
  end

  def exec(%__MODULE__{command: "CONFIG", arguments: arguments}) do
    case arguments do
      ["GET" | keys] ->
        key_values =
          Enum.flat_map(keys, fn key ->
            [key, Config.get(key)]
          end)

        Protocol.encode(key_values)

      _ ->
        Protocol.error("unknown command")
    end
  end

  def exec(%__MODULE__{command: "KEYS", arguments: arguments}) do
    [pattern] = arguments

    case Storage.keys(pattern) do
      {:ok, keys} -> Protocol.encode_list(keys)
      {:error, _} -> Protocol.null()
    end
  end

  def exec(%__MODULE__{command: "INFO", arguments: arguments}) do
    case arguments do
      [] ->
        info = Config.get(:port)
        Protocol.encode_list(info)

      ["replication"] ->
        handle_replication_info()

      _ ->
        Protocol.error("unknown command")
    end
  end

  def exec(%__MODULE__{command: "REPLCONF", arguments: _arguments}) do
    Protocol.encode("OK")
  end

  def exec(_request) do
    Protocol.error("unknown command")
  end

  defp handle_replication_info() do
    replicaof = Config.get(:replicaof)
    role = if replicaof, do: "slave", else: "master"

    info =
      [
        "role:#{role}",
        "master_replid:8371b4fb1155b71f4a04d3e1bc3e18c4a990aeeb",
        "master_repl_offset:0"
      ]
      |> Enum.join("\n")

    Protocol.encode_bulk_string(info)
  end
end
