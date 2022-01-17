defmodule SqlConv.DbWorker do
  use GenServer

  alias SqlConv.Database

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:start_new_db_work, file, data_chunk}, _from, state) do
    Database.insert_data_chunk(file, data_chunk)
    {:reply, {:ok, "chunk for #{file}"}, state}
  end

end
