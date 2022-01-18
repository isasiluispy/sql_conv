defmodule SqlConv.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp poolboy_worker_config() do
    [
      name: {:local, :worker},
      worker_module: SqlConv.Worker,
      size: 50,
      max_overflow: 2
    ]
  end

  defp poolboy_db_worker_config() do
    [
      name: {:local, :db_worker},
      worker_module: SqlConv.DbWorker,
      size: 50,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      SqlConv.Repo,
      SqlConv.Observer,
      SqlConv.MainServer,
      :poolboy.child_spec(:worker, poolboy_worker_config()),
      :poolboy.child_spec(:db_worker, poolboy_db_worker_config()),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SqlConv.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
