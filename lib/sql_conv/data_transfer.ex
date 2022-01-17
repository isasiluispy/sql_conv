defmodule SqlConv.DataTransfer do
  @timeout 60000

  alias NimbleCSV.RFC4180, as: CSV
  alias SqlConv.Helpers

  @doc """
  Divides a csv file in chunks and place them in a job queue.
  Whenever a DB worker is free it will pick up a chunk from the queue
  and insert it in the database.
  """
  def process_file(file) do
    Helpers.print_msg("Begin data tranfer for file: " <> Path.basename(file))

    insertion_chunk_size = Application.get_env(:sql_conv, SqlConv.Repo)[:insertion_chunk_size]

    file
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.chunk_every(insertion_chunk_size)
    |> Enum.map(fn data_chunk -> async_call_start_new_db_work(file, data_chunk) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_start_new_db_work(file, data_chunk) do
    Task.async(fn ->
      :poolboy.transaction(
        :db_worker,
        fn pid ->
          # Let's wrap the genserver call in a try - catch block. This allows us to trap any exceptions
          # that might be thrown and return the worker back to poolboy in a clean manner. It also allows
          # the programmer to retrieve the error and potentially fix it.
          try do
            GenServer.call(pid, {:start_new_db_work, file, data_chunk}, @timeout)
          catch
            e, r -> IO.inspect("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
            :ok
          end
        end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
