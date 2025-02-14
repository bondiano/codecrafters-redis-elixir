defmodule Redis.Runtime.Config do
  use GenServer

  @moduledoc """
  Configuration module for Redis runtime.
  """

  defstruct [:dir, :dbfilename]

  @options [dir: :string, dbfilename: :string]

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    {options, [], []} = OptionParser.parse(System.argv(), strict: @options)
    options = Enum.into(options, %{})
    {:ok, %__MODULE__{dir: options[:dir], dbfilename: options[:dbfilename]}}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def handle_call({:get, key}, _from, state) do
    value =
      case key do
        "dir" -> state.dir
        "dbfilename" -> state.dbfilename
      end

    {:reply, value, state}
  end
end
