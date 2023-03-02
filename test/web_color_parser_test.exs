defmodule Dash.WebColorParserTest do
  use ExUnit.Case

  alias Dash.WebColorParser

  doctest(WebColorParser)

  test "named colors" do
    WebColorParser.parse("red")
    |> IO.inspect(label: "res (web_color_parser_test.exs:10)")
  end

  test "hexcode" do
    # WebColorParser.parse("#FF0000")
    WebColorParser.parse("rgb(255, 0, 0)")
    |> IO.inspect(label: "res (web_color_parser_test.exs:15)")
  end
end
