defmodule Redis.Runtime.Config do
  use GenServer

  @moduledoc """
  Configuration module for Redis runtime.
  """

  defstruct [:dir, :dbfilename, :port, :replicaof]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t(),
          port: integer(),
          replicaof: String.t()
        }

  @options_spec [dir: :string, dbfilename: :string, port: :integer, replicaof: :string]

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
       port: Keyword.get(options, :port, @default_port),
       replicaof: Keyword.get(options, :replicaof)
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
        "replicaof" -> state.replicaof
        :replicaof -> state.replicaof
      end

    {:reply, value, state}
  end
end
