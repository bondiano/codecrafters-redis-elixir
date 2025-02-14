defmodule Redis.Impl.Storage do
  @type t :: map()
  @type value :: {any, expires_at :: integer}

  def new do
    Map.new()
  end

  @spec get(t(), String.t()) :: String.t() | nil
  def get(map, key) do
    current_time = System.system_time(:millisecond)

    case Map.get(map, key) do
      {value, expires_at} when expires_at == -1 -> value
      {value, expires_at} when expires_at > current_time -> value
      _ -> nil
    end
  end

  @spec set(t(), String.t(), String.t()) :: t()
  def set(map, key, value) do
    Map.put(map, key, {value, -1})
  end

  @spec set(t(), String.t(), String.t(), integer) :: t()
  def set(map, key, value, expiry) do
    expires_at = System.system_time(:millisecond) + expiry
    Map.put(map, key, {value, expires_at})
  end
end
