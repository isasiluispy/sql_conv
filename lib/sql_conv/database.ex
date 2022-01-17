defmodule SqlConv.Database do
  alias SqlConv.{Helpers, Observer}

  def make_db_schema([drop_query, create_query]) do
    try do
      execute_query(drop_query)
      execute_query(create_query)
    catch
      _, reason ->
        IO.inspect(reason, label: "Error: ")
    end

    log_table_created(drop_query)
  end

  @doc """
  Inserts a chunk of data in the database
  """
  def insert_data_chunk(file, data_chunk) do
    table_name = Helpers.get_table_name(file)

    headers = Helpers.get_headers(file)

    data_chunk =
      Enum.map(data_chunk, fn row ->
        row
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {col, index}, map ->
          header = Enum.at(headers, index)

          Map.put(map, header, col)
        end)
      end)

    try do
      SqlConv.Repo.insert_all(
        table_name,
        data_chunk
      )
    catch
      _, reason ->
        IO.inspect(reason, label: "Error")
    end

    Observer.update_file_status(file, :insert_data)
  end

  # Helpers

  defp execute_query(query) do
    SqlConv.Repo |> Ecto.Adapters.SQL.query!(query, [])
  end

  defp log_table_created(drop_query) do
    table_name =
      drop_query
      |> String.trim_leading("DROP TABLE IF EXISTS")
      |> String.trim_trailing(";")

    Helpers.print_msg("Create Schema for: #{table_name}")
  end
end
