import gleam/option
import grimoire/entity
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
      html.script([attribute.src("/assets/local.js")], ""),
    ]),
    html.body([lustre_hx.boost(True)], elements),
  ])
}

pub type EntityLinkState {
  None
  Highlighted
  Selected
}

pub fn entity_link(
  entity: entity.Entity,
  highlight_state: EntityLinkState,
  oob: Bool,
) {
  html.a(
    [
      lustre_hx.target(lustre_hx.CssSelector("#details")),
      attribute.id("entity_link_" <> entity.id),
      attribute.href("/" <> entity.id),
      attribute.class("entity-link p-2 rounded hover:bg-gray-300"),
      attribute.classes([
        #("highlighted", highlight_state == Highlighted),
        #("selected", highlight_state == Selected),
      ]),
    ]
      |> with_oob_swap(oob),
    [html.text(entity.name)],
  )
}

pub fn entity_detail(entity: entity.Entity) {
  html.div([attribute.class("flex gap-2")], [
    html.h1([], [html.text(entity.name)]),
    html.p([], [html.text(entity.description)]),
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
