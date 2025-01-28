import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/internals/vdom
import lustre_hx

pub fn layout(elements: List(Element(a))) {
  html.html([], [
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/assets/tailwind.min.css"),
      ]),
      html.script([attribute.src("/vendors/htmx-v2-0-4.min.js")], ""),
    ]),
    html.body([lustre_hx.boost(True)], elements),
  ])
}

pub fn entity_link(name: String, highlight: Bool, oob: Bool) {
  html.a(
    [
      lustre_hx.target(lustre_hx.CssSelector("#details")),
      attribute.id("entity_link_" <> name),
      attribute.href("/" <> name),
      attribute.class("p-2 rounded hover:bg-gray-300"),
      attribute.classes([
        #("bg-gray-200", !highlight),
        #("bg-orange-200", highlight),
      ]),
    ]
      |> with_oob_swap(oob),
    [html.text(name)],
  )
}

pub fn entity_detail(name: String, description: String) {
  html.div([attribute.class("flex gap-2")], [
    html.h1([], [html.text(name)]),
    html.p([], [html.text(description)]),
  ])
}

fn with_oob_swap(
  attributes: List(vdom.Attribute(b)),
  swap: Bool,
) -> List(vdom.Attribute(b)) {
  case swap {
    True -> [attribute.attribute("hx-swap-oob", "true"), ..attributes]
    False -> attributes
  }
}
