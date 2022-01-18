# SqlConv

It's a tool that will let you load light or huge CSV files into Postgres tables.

In a nutshell, the system will do the next steps in order:

- Read CSV files and get their table structure
- Create the tables based on the strcuture
- Insert all csv data into the correspondant table


SqlConv takes advantage of multi core processors doing most of its tasks in parallel, meaning it takes significantlly less time than
doing the same tasks in a single threaded application.

## Installation and usage
The version of the tools presented here are the ones I used and worked.

- Install [asdf](https://github.com/asdf-vm/asdf)
- Install erlang -> asdf install erlang 24.2 
- Install elixir -> asdf install elixir 1.13.2-otp-24
- In the root directory run:
  - mix deps.get
  - mix escript.build
  - mix ecto.create
  - ./sql_conv --db-connection-string "postgres:@localhost/sql_conv_repo"

And you should be able to have a fresh database with all CSVs as postgres tables.
