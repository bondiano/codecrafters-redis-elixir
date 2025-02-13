defmodule Redis.Impl.Command do
  @moduledoc """
  The Redis handler.
  """

  defstruct command: "", arguments: []

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

  def exec(_request) do
    "-ERR unknown command\r\n"
  end
end
