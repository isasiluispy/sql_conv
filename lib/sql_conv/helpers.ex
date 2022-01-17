defmodule SqlConv.Helpers do

  import IO.ANSI
  alias NimbleCSV.RFC4180, as: CSV

  def print_msg(msg, color \\ :blue) do
    color =
      case color do
        :blue -> blue()
        :green -> green()
        :red -> red()
        :yellow -> yellow()
        _ -> white()
      end

    color
    |> Kernel.<>(bright() <> msg <> reset())
    |> format()
    |> IO.puts()
  end

  def greet() do
    (green() <>
       bright() <>
       """
                      Welcome to oneHQ's SqlConverter Tool
       -----------------------------------------------------------------------
       """ <> reset())
    |> IO.puts()
  end

  def get_headers(path) do
    path
    |> File.stream!()
    |> Stream.take(1)
    |> CSV.parse_stream(skip_headers: false)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.map(&(replace_special_characters(&1)))
  end

  def get_table_name(file_path) do
    file_path
    |> Path.basename(".csv")
    |> String.downcase()
  end

  def update_config(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          schema_file_path: :string,
          source_csv_directory: :string,
          imported_csv_directory: :string,
          db_connection_string: :string,
          schema_infer_chunk_size: :integer,
          worker_count: :integer,
          db_worker_count: :integer,
          insertion_chunk_size: :integer,
          job_count_limit: :integer,
          timeout: :integer,
          log: :string
        ]
      )

    source_csv_directory = opts[:source_csv_directory] || "./data"
    schema_file_path = opts[:schema_file_path] || source_csv_directory
    imported_csv_directory = opts[:imported_csv_directory] || "#{source_csv_directory}/imported"

    [username, password, host, database_name] =
      if opts[:db_connection_string] do
        str = opts[:db_connection_string]
        [username, tmp] = String.split(str, ":")
        [password, tmp] = String.split(tmp, "@")
        [host, database_name] = String.split(tmp, "/")
        [username, password, host, database_name]
      end

    schema_infer_chunk_size = opts[:schema_infer_chunk_size] || 100
    worker_count = opts[:worker_count] || 10
    db_worker_count = opts[:db_worker_count] || 15
    insertion_chunk_size = opts[:insertion_chunk_size] || 100
    job_count_limit = opts[:job_count_limit] || 10
    timeout = opts[:timeout] || 60_000
    log = if opts[:log], do: String.to_atom(opts[:log]), else: false

    current_config = [
      sql_conv: [
        {
          SqlConv.Repo,
          [
            username: username,
            password: password,
            host: host,
            insertion_chunk_size: insertion_chunk_size,
            job_count_limit: job_count_limit,
            timeout: timeout,
            database: database_name,
            log: log
          ]
        },
        {
          SqlConv.SchemaMaker,
          [
            schema_file_path: schema_file_path,
            schema_infer_chunk_size: schema_infer_chunk_size
          ]
        },
        {
          SqlConv.MainServer,
          [
            worker_count: worker_count,
            db_worker_count: db_worker_count,
            source_csv_directory: source_csv_directory,
            imported_csv_directory: imported_csv_directory,
          ]
        }
      ]
    ]

    Application.put_all_env(current_config)

    current_config
  end

  defp replace_special_characters(name) do
    name
    |> String.downcase()
    |> String.replace("#", "_", global: true)
    |> String.replace(" ", "", global: true)
    |> String.replace("-", "_", global: true)
    |> String.replace("&", "_", global: true)
    |> String.replace("\"", "", global: true)
    |> String.replace("/", "", global: true)
    |> String.replace("'", "", global: true)
    |> String.replace("(", "", global: true)
    |> String.replace(")", "", global: true)
    |> String.replace("%", "_", global: true)
    |> String.replace("?", "", global: true)
    |> String.replace(".", "", global: true)
    |> String.replace(":", "", global: true)
  end

end
