import gleam/list
import gleam/option
import gleam/string
import lustre/element/html

/// From text to HTML, with custom changes
pub fn parse(text: String) {
  text
  |> string.replace(each: "\r\n", with: "\n")
  |> string.split(on: "\n")
  |> list.map(parse_line)
  |> option.values
}

fn parse_line(line: String) {
  case string.trim(line) {
    "# " <> text -> option.Some(html.h1([], [html.text(text)]))
    "## " <> text -> option.Some(html.h2([], [html.text(text)]))
    "" -> option.None
    otherwise -> option.Some(html.p([], [html.text(otherwise)]))
  }
}
