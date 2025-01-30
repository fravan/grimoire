import gleeunit
import gleeunit/should
import grimoire/parser
import lustre/attribute
import lustre/element/html
import lustre_hx

pub fn main() {
  gleeunit.main()
}

pub fn simple_paragraph_test() {
  parser.parse("Link is a knight.")
  |> should.equal([html.p([], [html.text("Link is a knight.")])])
}

pub fn multiple_simple_paragraph_test() {
  parser.parse("Link is a knight.\n\nZelda is a princess.")
  |> should.equal([
    html.p([], [html.text("Link is a knight.")]),
    html.p([], [html.text("Zelda is a princess.")]),
  ])
}

pub fn multiple_simple_paragraph_return_carriage_test() {
  parser.parse("Link is a knight.\r\n\r\nZelda is a princess.")
  |> should.equal([
    html.p([], [html.text("Link is a knight.")]),
    html.p([], [html.text("Zelda is a princess.")]),
  ])
}

pub fn simple_h2_test() {
  parser.parse("# Link, the knight")
  |> should.equal([html.h2([], [html.text("Link, the knight")])])
}

pub fn simple_h3_test() {
  parser.parse("## Link, the knight")
  |> should.equal([html.h3([], [html.text("Link, the knight")])])
}

pub fn paragraph_with_headings_test() {
  parser.parse("# Link, the knight\n\n## General\n\nLink is great")
  |> should.equal([
    html.h2([], [html.text("Link, the knight")]),
    html.h3([], [html.text("General")]),
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
    html.h2([], [html.text("Link, the knight")]),
    html.h3([], [html.text("General")]),
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

pub fn entity_reference_with_name_test() {
  parser.parse(
    "He is [Zelda][dtt]'s knight

    [dtt]: /dtt",
  )
  |> should.equal([
    html.p([], [
      html.text("He is "),
      html.a(
        [
          lustre_hx.target(lustre_hx.CssSelector("#details")),
          attribute.href("/dtt"),
        ],
        [html.text("Zelda")],
      ),
      html.text("'s knight"),
    ]),
  ])
}
