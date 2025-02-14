defmodule Redis.Runtime.Storage do
  use GenServer

  alias Redis.Impl.Storage

  @type t :: pid()
  @type key :: String.t()
  @type value :: any()
  @type result :: {:ok, value()} | {:error, atom()}

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, [], name: @me)
  end

  @impl true
  def init(_) do
    {:ok, Storage.new()}
  end

  @spec get(key()) :: result()
  def get(key) do
    GenServer.call(@me, {:get, key})
  end

  def set(key, value) do
    GenServer.call(@me, {:set, key, value})
  end

  def set(key, value, expiry) do
    GenServer.call(@me, {:set, key, value, expiry})
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
end
