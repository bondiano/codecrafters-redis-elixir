defmodule Redis.Runtime.Storage do
  @moduledoc """
  Storage GenServer.
  """

  use GenServer

  require Logger

  alias Redis.Impl.Storage
  alias Redis.Runtime.Config
  alias Redis.Impl.RdbParser

  @type t :: pid()
  @type key :: String.t()
  @type value :: any()
  @type result :: {:ok, value()} | {:error, atom()}

  @me __MODULE__

  @spec start_link(init_state :: map()) :: GenServer.on_start()
  def start_link(init_state) do
    GenServer.start_link(@me, init_state, name: @me)
  end

  @impl true
  def init(_) do
    dir = Config.get(:dir)
    filename = Config.get(:dbfilename)

    init_data = load_init_data(dir, filename)

    {:ok, init_data}
  end

  @spec get(key()) :: result()
  def get(key) do
    GenServer.call(@me, {:get, key})
  end

  @spec set(key(), value()) :: result()
  def set(key, value) do
    GenServer.call(@me, {:set, key, value})
  end

  @spec set(key(), value(), integer()) :: result()
  def set(key, value, expiry) do
    GenServer.call(@me, {:set, key, value, expiry})
  end

  @spec keys(pattern :: String.t()) :: result()
  def keys(pattern) do
    GenServer.call(@me, {:keys, pattern})
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Storage.get(state, key)
    {:reply, {:ok, value}, state}
  end

  @impl true
  def handle_call({:set, key, value}, _from, state) do
    new_state = Storage.set(state, key, value)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:set, key, value, expiry}, _from, state) do
    new_state = Storage.set(state, key, value, expiry)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:keys, pattern}, _from, state) do
    keys = Storage.keys(state, pattern)
    {:reply, {:ok, keys}, state}
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
