import gleeunit
import gleeunit/should
import grimoire/parser
import lustre/element/html

pub fn main() {
  gleeunit.main()
}

pub fn simple_paragraph_test() {
  parser.parse("Link is a knight.")
  |> should.equal([html.p([], [html.text("Link is a knight.")])])
}

pub fn multiple_simple_paragraph_test() {
  parser.parse("Link is a knight.\nZelda is a princess.")
  |> should.equal([
    html.p([], [html.text("Link is a knight.")]),
    html.p([], [html.text("Zelda is a princess.")]),
  ])
}

pub fn multiple_simple_paragraph_return_carriage_test() {
  parser.parse("Link is a knight.\r\nZelda is a princess.")
  |> should.equal([
    html.p([], [html.text("Link is a knight.")]),
    html.p([], [html.text("Zelda is a princess.")]),
  ])
}

pub fn simple_h1_test() {
  parser.parse("# Link, the knight")
  |> should.equal([html.h1([], [html.text("Link, the knight")])])
}

pub fn simple_h2_test() {
  parser.parse("## Link, the knight")
  |> should.equal([html.h2([], [html.text("Link, the knight")])])
}

pub fn paragraph_with_headings_test() {
  parser.parse("# Link, the knight\n## General\nLink is great")
  |> should.equal([
    html.h1([], [html.text("Link, the knight")]),
    html.h2([], [html.text("General")]),
    html.p([], [html.text("Link is great")]),
  ])
}

pub fn paragraph_with_whitespace_test() {
  parser.parse(
    "# Link, the knight
    ## General
    Link is great",
  )
  |> should.equal([
    html.h1([], [html.text("Link, the knight")]),
    html.h2([], [html.text("General")]),
    html.p([], [html.text("Link is great")]),
  ])
}

pub fn ignore_empty_lines_test() {
  parser.parse(
    "Link is great.

    So is Zelda.",
  )
  |> should.equal([
    html.p([], [html.text("Link is great.")]),
    html.p([], [html.text("So is Zelda.")]),
  ])
}
