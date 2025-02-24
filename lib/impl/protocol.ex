defmodule Redis.Impl.Protocol do
  @moduledoc """
  This module provides functions for encoding and decoding Redis protocol messages.
  """

  @spec encode(payload :: any) :: String.t()
  def encode(payload) do
    case payload do
      nil -> encode_simple_string(nil)
      [string] when is_binary(string) -> encode_bulk_string(string)
      string when is_binary(string) -> encode_simple_string(string)
      [_ | _] -> encode_list(payload)
    end
  end

  def null(), do: "$-1\r\n"

  def error(message) do
    "-#{message}\r\n"
  end

  def encode_list(array) do
    "*#{Enum.count(array)}\r\n" <> Enum.map_join(array, "", &encode_bulk_string/1)
  end

  def encode_bulk_string(nil), do: null()

  def encode_bulk_string(string) do
    "$#{byte_size(string)}\r\n#{string}\r\n"
  end

  def encode_simple_string(nil), do: null()

  def encode_simple_string(string) do
    if String.match?(string, ~r/\n|\r/) do
      {:error, "String contains invalid characters"}
    else
      "+#{string}\r\n"
    end
  end

  def encode_binary_file(bin) do
    "$#{byte_size(bin)}\r\n#{bin}"
  end

  @spec decode(String.t()) :: {:ok, list(String.t())} | {:error, String.t()}
  def decode(string) do
    {:ok, command, []} =
      string
      |> String.split("\r\n", trim: true)
      |> do_decode()

    {:ok, command}
  end

  defp do_decode(["$" <> n, string | rest]) do
    {length, ""} = Integer.parse(n)

    if length == byte_size(string) do
      {:ok, string, rest}
    else
      {:error, "Invalid bulk string length"}
    end
  end

  defp do_decode(["*" <> n | rest]) do
    {count, ""} = Integer.parse(n)
    decode_array(count, [], rest)
  end

  defp decode_array(0, acc, rest), do: {:ok, Enum.reverse(acc), rest}

  defp decode_array(n, acc, rest) do
    case rest |> do_decode() do
      {:ok, value, rest} ->
        decode_array(n - 1, [value | acc], rest)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec empty_database!() :: binary()
  def empty_database!() do
    {:ok, empty_file} =
      Base.decode64(
        "UkVESVMwMDEx+glyZWRpcy12ZXIFNy4yLjD6CnJlZGlzLWJpdHPAQPoFY3RpbWXCbQi8ZfoIdXNlZC1tZW3CsMQQAPoIYW9mLWJhc2XAAP/wbjv+wP9aog==",
        ignore: :whitespace
      )

    empty_file
  end
end
