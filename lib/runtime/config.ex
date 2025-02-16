defmodule Redis.Runtime.Config do
  use GenServer

  @moduledoc """
  Configuration module for Redis runtime.
  """

  defstruct [:dir, :dbfilename]

  @type t :: %__MODULE__{dir: String.t(), dbfilename: String.t()}

  @options_spec [dir: :string, dbfilename: :string]

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {options, [], []} = OptionParser.parse(System.argv(), strict: @options_spec)
    options = Enum.into(options, %{})

    {:ok, %__MODULE__{dir: options[:dir], dbfilename: options[:dbfilename]}}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl true
  @spec handle_call(request :: tuple(), from :: term(), state :: t()) :: {:reply, term(), t()}
  def handle_call({:get, key}, _from, state) do
    value =
      case key do
        "dir" -> state.dir
        :dir -> state.dir
        "dbfilename" -> state.dbfilename
        :dbfilename -> state.dbfilename
      end

    {:reply, value, state}
  end
end
