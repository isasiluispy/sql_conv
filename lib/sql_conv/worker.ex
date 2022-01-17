defmodule SqlConv.Worker do
  use GenServer

  alias SqlConv.Observer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:start_new_work, file, row_count}, _from, state) do

    Observer.update_file_status(file, :infer_schema)
    result = make_schema(file)

    Observer.update_file_status(file, :insert_schema)
    insert_schema(result)

    if row_count != 0 do
      Observer.update_file_status(file, :insert_data)
      insert_data(file)
    else
      handle_empty_file(file)
    end

    {:reply, {:ok, file}, state}
  end

  # Helpers

  defp make_schema(file) do
    queries = SqlConv.SchemaMaker.make_schema(file)
    {file, queries}
  end

  defp insert_schema({file, queries}) do
    SqlConv.Database.make_db_schema(queries)
    file
  end

  # Handle csvs having 0 rows, change status to finish and move to imported directory
  defp handle_empty_file(file) do
    Observer.update_file_status(file, :finish)

    File.rename!(
      file,
      "#{Application.get_env(:sql_conv, SqlConv.MainServer)[:imported_csv_directory]}/#{
        Path.basename(file)
      }"
    )
  end

  defp insert_data(file) do
    SqlConv.DataTransfer.process_file(file)
    file
  end
end
