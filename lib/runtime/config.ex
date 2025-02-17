defmodule Redis.Runtime.Config do
  use GenServer

  @moduledoc """
  Configuration module for Redis runtime.
  """

  defstruct [:dir, :dbfilename, :port]

  @type t :: %__MODULE__{dir: String.t(), dbfilename: String.t(), port: integer()}

  @options_spec [dir: :string, dbfilename: :string, port: :integer]

  @default_port 6379

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {options, [], []} = OptionParser.parse(System.argv(), strict: @options_spec)

    {:ok,
     %__MODULE__{
       dir: Keyword.get(options, :dir),
       dbfilename: Keyword.get(options, :dbfilename),
       port: Keyword.get(options, :port, @default_port)
     }}
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
        "port" -> state.port
        :port -> state.port
      end

    {:reply, value, state}
  end
end
