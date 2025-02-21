defmodule Redis.Runtime.Storage do
  @moduledoc """
  Storage Agent.
  """

  require Logger
  use Agent

  alias Redis.Impl.Storage
  alias Redis.Runtime.Config
  alias Redis.Impl.RdbParser

  @type t :: pid()
  @type key :: String.t()
  @type value :: any()
  @type result :: {:ok, value()} | {:error, atom()}
  @type simple_result :: :ok | {:error, atom()}

  @me __MODULE__

  @spec start_link(init_state :: map()) :: Agent.on_start()
  def start_link(_init_state) do
    dir = Config.get(:dir)
    filename = Config.get(:dbfilename)

    Agent.start_link(fn -> load_init_data(dir, filename) end, name: @me)
  end

  @spec get(key()) :: result()
  def get(key) do
    case Agent.get(@me, &Storage.get(&1, key)) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @spec set(key(), value()) :: simple_result()
  def set(key, value) do
    Agent.update(@me, &Storage.set(&1, key, value))
  end

  @spec set(key(), value(), integer()) :: simple_result()
  def set(key, value, expiry) do
    Agent.update(@me, &Storage.set(&1, key, value, expiry))
  end

  @spec keys(pattern :: String.t()) :: result()
  def keys(pattern) do
    case Agent.get(@me, &Storage.keys(&1, pattern)) do
      nil -> {:error, :not_found}
      keys -> {:ok, keys}
    end
  end

  defp load_init_data(nil, _), do: %{}
  defp load_init_data(_, nil), do: %{}

  defp load_init_data(dir, filename) do
    with {:ok, data} <- Path.join(dir, filename) |> File.read(),
         {:ok, parsed} <- RdbParser.parse(data) do
      parsed
    else
      {:error, error} ->
        Logger.error("Error parsing RDB file: #{inspect(error)}")
        %{}
    end
  end
end
