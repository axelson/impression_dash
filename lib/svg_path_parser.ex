defmodule Dash.SvgPathParser do
  @moduledoc """
  Parses svg paths

  Some code based upon exsel https://github.com/slapers/ex_sel and licensed
  Apache 2.0
  """

  import NimbleParsec

  digits = [?0..?9] |> ascii_string(min: 1) |> label("digits")
  whitespace = ascii_char([?\s, ?\t, ?\n]) |> times(min: 1)

  int =
    optional(string("-"))
    |> concat(digits)
    |> reduce(:to_integer)
    |> label("integer")

  defp to_integer(acc), do: acc |> Enum.join() |> String.to_integer(10)

  float =
    optional(string("-"))
    |> concat(digits)
    |> ascii_string([?.], 1)
    |> concat(digits)
    |> reduce(:to_float)
    |> label("float")

  defp to_float(acc), do: acc |> Enum.join() |> String.to_float()

  number = [float, int] |> choice() |> label("number")
  whitespace_or_comma = choice([whitespace, string(",")])

  # A parameter is like the first number in a coordinate
  parameter =
    ignore(optional(whitespace))
    |> concat(number)
    |> ignore(optional(whitespace_or_comma))

  parameters = parameter |> times(min: 1)

  coordinate =
    ignore(optional(whitespace))
    |> concat(number)
    |> ignore(optional(whitespace_or_comma))
    |> concat(number)
    |> ignore(optional(whitespace_or_comma))
    |> reduce(:to_coordinate)

  defp to_coordinate([x, y]), do: {x, y}

  coordinate_pairs = coordinate |> times(min: 1)

  abs_move_to =
    ignore(string("M"))
    |> concat(coordinate_pairs)
    |> label("absolute move to")
    |> tag(:abs_move_to)

  rel_move_to =
    ignore(string("M"))
    |> concat(coordinate)
    |> label("relative move to")
    |> tag(:rel_move_to)

  abs_line_to =
    ignore(string("L"))
    |> concat(coordinate)
    |> label("absolute line to")
    |> tag(:abs_line_to)

  rel_line_to =
    ignore(string("l"))
    |> concat(coordinate)
    |> label("relative line to")
    |> tag(:rel_line_to)

  abs_vertical_line =
    ignore(string("V"))
    |> concat(parameters)
    |> label("absolute vertical line")
    |> tag(:abs_vertical_line_to)

  rel_vertical_line =
    ignore(string("V"))
    |> concat(parameters)
    |> label("relative vertical line")
    |> tag(:rel_vertical_line_to)

  abs_horizontal_line =
    ignore(string("H"))
    |> concat(parameters)
    |> label("absolute horizontal line")
    |> tag(:abs_horizontal_line_to)

  rel_horizontal_line =
    ignore(string("h"))
    |> concat(parameters)
    |> label("relative horizontal line")
    |> tag(:rel_horizontal_line_to)

  close_path =
    ignore(choice([string("Z"), string("z")]))
    |> label("close path")
    |> replace(:close_path)

  command =
    choice([
      abs_move_to,
      rel_move_to,
      abs_line_to,
      rel_line_to,
      abs_vertical_line,
      rel_vertical_line,
      abs_horizontal_line,
      rel_horizontal_line,
      close_path
    ])
    |> label("command")

  defparsec(:raw_parse, repeat(command))

  def parse(string) do
    raw_parse(string)
    |> unwrap_result()
  end

  defp unwrap_result(result) do
    case result do
      {:ok, acc, "", _, _line, _offset} ->
        {:ok, acc}

      {:ok, _, rest, _, _line, _offset} ->
        {:error, "could not parse: " <> rest}
    end
  end
end
