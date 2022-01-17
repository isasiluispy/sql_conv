defmodule SqlConv.SchemaMaker do

  alias SqlConv.{Helpers, Observer}

  @doc """
  Writes the DDL queries in file
  """
  def make_schema(file_path) do
    [drop_query, create_query] =
      file_path
      |> get_types()
      |> get_ddl_queries(file_path)

    query = """

    #{drop_query}

    #{create_query}

    """
    schema_file_path = Application.get_env(:sql_conv, SqlConv.SchemaMaker)[:schema_file_path]
    File.write("#{schema_file_path}/schema.sql", query, [:append])
    SqlConv.Helpers.print_msg("Infer Schema for: #{Path.basename(file_path)}")
    [drop_query, create_query]
  end

  defp get_types(path) do
    headers = Helpers.get_headers(path)

    types =
      headers
      |> Enum.reduce([], fn header, acc ->
        acc ++ [{header, "TEXT"}]
      end)

    Observer.set_schema(path, types)

    types
  end

  defp get_ddl_queries(types, file_path) do
    table_name = "\"#{Helpers.get_table_name(file_path)}\""

    create_table =
      types
      |> Enum.reduce(
        "CREATE TABLE #{table_name} (",
        fn {column_name, type}, query ->
          column_name = "\"#{column_name}\""
          query <> "#{column_name} #{type}, "
        end
      )
      |> String.trim_trailing(", ")
      |> Kernel.<>(");")

    ["DROP TABLE IF EXISTS #{table_name};", "#{create_table}"]
  end

end
