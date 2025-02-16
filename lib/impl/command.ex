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
    "+PONG\r\n"
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

    "+OK\r\n"
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
        "-ERR unknown command\r\n"
    end
  end

  def exec(%__MODULE__{command: "KEYS", arguments: arguments}) do
    [pattern] = arguments
    {:ok, keys} = Storage.keys(pattern)
    Protocol.encode_list(keys)
  end

  def exec(_request) do
    "-ERR unknown command\r\n"
  end
end
