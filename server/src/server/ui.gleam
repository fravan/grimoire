import gleam/list
import server/entity
import server/htmx
import server/parser
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre_hx

pub fn layout(elements: List(Element(a))) {
  html.html([], [
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/assets/tailwind.min.css"),
      ]),
      html.script([attribute.src("/vendors/htmx-v2-0-4.min.js")], ""),
      html.script([attribute.src("/assets/local.min.mjs")], ""),
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
      |> htmx.with_oob_swap(oob),
    [html.text(entity.name)],
  )
}

pub fn entity_detail(entity: entity.Entity, all_entities: List(entity.Entity)) {
  // add all the entities as reference if used in a link in description.
  let final_description =
    list.fold(
      all_entities,
      from: entity.description <> "\n",
      with: fn(acc, entity) {
        acc <> "\n" <> "[" <> entity.id <> "]: /" <> entity.id
      },
    )

  html.div([attribute.class("entity-details")], [
    html.h1([], [html.text(entity.name)]),
    ..parser.parse(final_description)
  ])
}
