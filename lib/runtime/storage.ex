defmodule Redis.Runtime.Storage do
  use GenServer

  alias Redis.Impl.Storage

  @type t :: pid()

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, [], name: @me)
  end

  def init(_) do
    {:ok, Storage.new()}
  end

  def get(key) do
    GenServer.call(@me, {:get, key})
  end

  def set(key, value) do
    GenServer.call(@me, {:set, key, value})
  end

  def handle_call({:get, key}, _from, state) do
    value = Storage.get(state, key)
    {:reply, {:ok, value}, state}
  end

  def handle_call({:set, key, value}, _from, state) do
    new_state = Storage.set(state, key, value)
    {:reply, :ok, new_state}
  end
end
