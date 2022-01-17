defmodule SqlConv.Observer do
  use GenServer

  alias NimbleCSV.RFC4180, as: CSV

  @status_list [:pending, :infer_schema, :insert_schema, :insert_data, :finish]
  @stage_list [:loading_files, :waiting, :working, :validation, :finish, :error]

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def update_file_status(file, new_status) do
    GenServer.cast(__MODULE__, {:update_status, file, new_status})
  end

  def set_schema(file, schema) do
    GenServer.call(__MODULE__, {:set_schema, file, schema}, :infinity)
  end

  def get_files() do
    GenServer.call(__MODULE__, :get_files, :infinity)
  end

  def get_stage do
    GenServer.call(__MODULE__, :get_stage, :infinity)
  end

  def change_stage(new_stage) do
    GenServer.cast(__MODULE__, {:change_stage, new_stage})
  end

  def init(_) do
    {:ok,
     %{
       start_time: DateTime.utc_now(),
       file_list: %{},
       files_to_process: [],
       stage: :loading_files,
       validation_status: nil
     }, {:continue, :load_files}}
  end

  def handle_continue(:load_files, state) do
    {files_map, files_to_process} = get_file_list()

    {:noreply,
     Map.merge(
       state,
       %{stage: :working, file_list: files_map, files_to_process: files_to_process}
     )}
  end

  def handle_call(:get_stage, _from, %{stage: stage} = state) do
    {:reply, stage, state}
  end

  def handle_call(:get_files, _from, %{file_list: files_map, files_to_process: files_to_process} = state) do

    my_map =
      files_to_process
      |> Enum.map(fn file ->
        %{row_count: row_count} = files_map[file]
        {file, row_count}
      end)

    {:reply, my_map, state}
  end

  def handle_call({:set_schema, file, schema}, _from, %{file_list: file_list} = state) do
    {_, file_list} =
      Map.get_and_update(file_list, file, fn file_struct ->
        {file, Map.put(file_struct, :schema, schema)}
      end)

    {:reply, nil, Map.put(state, :file_list, file_list)}
  end

  def handle_cast({:change_stage, new_stage}, state) when new_stage in @stage_list do
    {:noreply, Map.put(state, :stage, new_stage)}
  end

  def handle_cast(
        {:update_status, file, status},
        state
      )
      when status in @status_list do
    file_struct = state.file_list[file]

    new_status =
      case {file_struct.status, status} do
        {{:insert_data, progress}, :insert_data} ->
          current_progress = progress + Application.get_env(:sql_conv, SqlConv.Repo)[:insertion_chunk_size]

          if current_progress >= file_struct.row_count,
            do: :finish,
            else: {:insert_data, current_progress}

        {_, :insert_data} ->
          {:insert_data, 0}

        _ ->
          status
      end

    file_struct = %{state.file_list[file] | status: new_status}

    {
      :noreply,
      Map.put(
        state,
        :file_list,
        Map.put(state.file_list, file, file_struct)
      )
    }
  end

  defp get_file_list() do
    source_dir = Application.get_env(:sql_conv, SqlConv.MainServer)[:source_csv_directory]

    IO.inspect(source_dir, label: "source dir")

    source_dir
    |> File.ls!()
    |> Enum.reject(fn file ->
      extension =
        file
        |> String.slice(-4..-1)
        |> String.downcase()

      extension != ".csv"
    end)
    |> Enum.reduce({%{}, []}, fn file, {file_map, file_list} ->
      path = "#{source_dir}/#{file}"

      %{size: size} = File.stat!(path)

      file_struct = %{
        name: String.slice(file, 0..-5),
        path: path,
        raw_size: size,
        humanised_size: Sizeable.filesize(size),
        row_count: get_count_from_csv(path),
        status: :pending
      }

      {Map.put(file_map, path, file_struct), file_list ++ [path]}
    end)
  end

  defp get_count_from_csv(file) do
    file
    |> File.stream!()
    |> CSV.parse_stream()
    |> Enum.count()
  end

end
