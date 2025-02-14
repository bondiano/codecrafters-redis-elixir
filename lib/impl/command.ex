defmodule Redis.Impl.Command do
  @moduledoc """
  The Redis handler.
  """

  defstruct command: "", arguments: []

  alias Redis.Runtime.Storage

  @type t :: %__MODULE__{
          command: String.t(),
          arguments: list()
        }

  @doc """
  Parses request to command and arguments.
  """
  @spec parse(String.t()) :: t()
  def parse(request) do
    [command | arguments] =
      request
      |> String.trim("\r\n")
      |> String.split("\r\n")
      |> Enum.slice(2..-1//1)
      |> Enum.take_every(2)

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
      {:ok, nil} -> "$-1\r\n"
      {:ok, value} -> "$#{String.length(value)}\r\n#{value}\r\n"
      {:error, _} -> "$-1\r\n"
    end
  end

  def exec(_request) do
    "-ERR unknown command\r\n"
  end
end
