import Config

config :sql_conv,
   ecto_repos: [SqlConv.Repo]

config :sql_conv, SqlConv.Repo,
  database: "sql_conv_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
