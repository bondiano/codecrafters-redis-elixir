defmodule Redis.Impl.Storage do
  @type t :: map()

  def new do
    Map.new()
  end

  @spec get(t(), String.t()) :: String.t() | nil
  def get(map, key) do
    Map.get(map, key)
  end

  @spec set(t(), String.t(), String.t()) :: t()
  def set(map, key, value) do
    Map.put(map, key, value)
  end
end
