defmodule SqlConv.Repo do
  use Ecto.Repo,
    otp_app: :sql_conv,
    adapter: Ecto.Adapters.Postgres
end
