defmodule SqlConv do

  alias SqlConv.Helpers

  def main(args) do
    SqlConv.Helpers.greet()

    # Load configuration varaibles dynamically for escripts, this is required
    # since configuration variables are set to whatever they where when the
    # escript was build and cannot be changed later
    Helpers.update_config(args)

    # Start supervision tree
    {:ok, sup_pid} = SqlConv.Application.start(:no_args, :no_args)

    # Wait for finish and stop supervion tree
    # This is done in separate Task to reply back to the caller(dashbaord GUI)
    # immediately after the supervision tree is started successfully
    Task.start(fn -> wait_for_finish(sup_pid) end)


    # In escripts as soon as the main() function return, the escript ends,
    # this allows the escript to keep running
    receive do
      {:wait} ->
        System.halt(0)
    end

    sup_pid
  end

  defp wait_for_finish(sup_pid) do
    SqlConv.Observer.get_stage()
    |> case do
      :error ->
        nil

      :finish ->
        # Finish and stop supervisors after a second
        IO.puts("Finishing Supervisor")
        :timer.sleep(1000)
        Supervisor.stop(sup_pid)

      _ ->
        wait_for_finish(sup_pid)
    end
  end
end
