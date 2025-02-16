defmodule Redis.Impl.RdbParser do
  @moduledoc """
    Parses Redis RDB files.
  """

  @type t :: map()

  @spec parse(binary()) :: {:ok, t()} | {:error, String.t()}
  def parse(bytes) do
    result = bytes |> skip_header!() |> skip_metadata!() |> parse_database_section!()
    {:ok, result}
  rescue
    error -> {:error, error}
  end

  @doc """
    Encodes a size from a binary.
    See https://rdb.fnordig.de/file_format.html#length-encoding
  """
  def encode_size(<<0b00::2, size::big-integer-size(6), rest::binary>>), do: {size, rest}
  def encode_size(<<0b01::2, size::big-integer-size(14), rest::binary>>), do: {size, rest}

  def encode_size(<<0b10::2, _::6, size::little-integer-size(32), rest::binary>>),
    do: {size, rest}

  def encode_size(<<0b11::2, 0::6, rest::binary>>), do: {:int8, rest}

  def encode_size(<<0b11::2, 1::6, rest::binary>>), do: {:int16, rest}

  def encode_size(<<0b11::2, 2::6, rest::binary>>), do: {:int32, rest}

  def encode_size(bytes), do: raise("Invalid size encoding: #{inspect(bytes)}")

  def encode_string(bytes) do
    {size, rest} = encode_size(bytes)

    case size do
      :int8 ->
        <<int::integer-little-size(8), rest::binary>> = rest
        {Integer.to_string(int), rest}

      :int16 ->
        <<int::integer-little-size(16), rest::binary>> = rest
        {Integer.to_string(int), rest}

      :int32 ->
        <<int::integer-little-size(32), rest::binary>> = rest
        {Integer.to_string(int), rest}

      size when is_integer(size) ->
        <<data::binary-size(size), rest::binary>> = rest
        {data, rest}
    end
  end

  def skip_header!(<<"REDIS", _ver::binary-size(4), rest::binary>>), do: rest
  def skip_header!(bytes), do: raise("Invalid RDB header: #{inspect(bytes)}")

  def skip_metadata!(bytes) do
    case bytes do
      <<0xFA, rest::binary>> ->
        {_key, rest} = encode_string(rest)
        {_value, rest} = encode_string(rest)
        skip_metadata!(rest)

      bytes ->
        bytes
    end
  end

  def parse_database_section!(bytes), do: do_parse_database_section!(%{}, bytes)

  def do_parse_database_section!(acc, bytes) do
    case bytes do
      <<0xFE, _index, 0xFB, kv, _expiry, rest::binary>> ->
        {acc, rest} = parse_kv!(acc, rest, kv)
        do_parse_database_section!(acc, rest)

      <<0xFF, _rest::binary>> ->
        acc

      <<>> ->
        acc
    end
  end

  defp parse_kv!(map, bytes, 0), do: {map, bytes}

  defp parse_kv!(map, bytes, kv_to_parse) do
    {expiry, rest} =
      case bytes do
        <<0, rest::binary>> ->
          {-1, rest}

        <<0xFC, expires_at::little-integer-size(64), 0, rest::binary>> ->
          {expires_at, rest}

        <<0xFD, expires_at::little-integer-size(32), 0, rest::binary>> ->
          {expires_at * 1000, rest}
      end

    {key, rest} = encode_string(rest)
    {value, rest} = encode_string(rest)

    parse_kv!(Map.put(map, key, {value, expiry}), rest, kv_to_parse - 1)
  end
end
