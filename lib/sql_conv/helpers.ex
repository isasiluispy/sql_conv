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



       #     #  #####   #####   #####  #     #  #####   #####   #####  #
       #     # #     # #     # #     # #     # #     # #     # #     # #
       #     # #     # #       #       #     #       # #       #     # #
       ####### #     # #        #####  #     #  #####   #####  #     # #
       #     # #   # # #             #  #   #  #             # #   # # #
       #     # #    #  #     # #     #   # #   #       #     # #    #  #
       #     #  #### #  #####   #####     #    #######  #####   #### # #######

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
