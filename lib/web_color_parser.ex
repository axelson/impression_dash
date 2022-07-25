defmodule Dash.WebColorParser do
  @moduledoc """
  Parses web colors

  iex> Dash.WebColorParser.parse("rgba(0, 200.5, 50, 0.2)")
  {:ok, {:rgba, [0, 200.5, 50, 0.2]}}

  iex> Dash.WebColorParser.parse("rgb(0, 255, 50)")
  {:ok, {:rgb, [0, 255, 50]}}
  """

  import NimbleParsec

  digits = [?0..?9] |> ascii_string(min: 1) |> label("digits")
  whitespace = ascii_char([?\s, ?\t, ?\n]) |> times(min: 1)
  whitespace_or_comma = choice([whitespace, string(",")])
  separator = repeat(whitespace_or_comma)

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

  rgb =
    ignore(string("rgb"))
    |> ignore(string("("))
    |> concat(number)
    |> concat(ignore(separator))
    |> concat(number)
    |> concat(ignore(separator))
    |> concat(number)
    |> concat(ignore(separator))
    |> ignore(string(")"))
    |> reduce(:to_rgb)
    |> unwrap_and_tag(:rgb)

  defp to_rgb([r, g, b]), do: {r, g, b}

  rgba =
    ignore(string("rgba"))
    |> ignore(string("("))
    |> concat(number)
    |> concat(ignore(separator))
    |> concat(number)
    |> concat(ignore(separator))
    |> concat(number)
    |> concat(ignore(separator))
    |> concat(number)
    |> concat(ignore(separator))
    |> ignore(string(")"))
    |> reduce(:to_rgba)
    |> unwrap_and_tag(:rgba)

  defp to_rgba([r, g, b, a]), do: {r, g, b, a}

  color = [rgb, rgba] |> choice() |> label("color")

  defparsec(:raw_parse, color)

  def parse(string) do
    raw_parse(string)
    |> unwrap_result()
  end

  defp unwrap_result(result) do
    case result do
      {:ok, [acc], "", _, _line, _offset} ->
        {:ok, acc}

      {:ok, _, rest, _, _line, _offset} ->
        {:error, "could not parse: " <> rest}
    end
  end
end
