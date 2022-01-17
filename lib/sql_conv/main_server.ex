defmodule SqlConv.MainServer do
  @timeout 60000

  use GenServer

  alias SqlConv.Observer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :kickoff, 0)
    {:ok, nil}
  end

  def handle_info(:kickoff, state) do
    Observer.get_files()
    |> Enum.map(fn {file, row_count} -> async_call_start_new_work(file, row_count) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)

    # once is here means the conversion has ended
    Observer.change_stage(:finish)

    {:noreply, state}
  end

  defp async_call_start_new_work(file, row_count) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid ->
          # Let's wrap the genserver call in a try - catch block. This allows us to trap any exceptions
          # that might be thrown and return the worker back to poolboy in a clean manner. It also allows
          # the programmer to retrieve the error and potentially fix it.
          try do
            GenServer.call(pid, {:start_new_work, file, row_count}, @timeout)
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
