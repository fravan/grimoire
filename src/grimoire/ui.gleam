import gleam/list
import gleam/string_tree
import grimoire/entity
import grimoire/htmx
import grimoire/parser
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
      |> htmx.with_oob_swap(oob),
    [html.text(entity.name)],
  )
}

pub fn entity_detail(entity: entity.Entity, all_entities: List(entity.Entity)) {
  // let parsed_description = entity.description
  // |> string_tree.from_string
  // let final_description = list.fold(all_entities, from: parsed_description, with: fn(acc, current) {
  //   let entity.Entity(id:, name:, ..) = current
  //   acc |> string_tree.replace(each: "@@" <> id <> "@@", with: name)
  // })
  // |> string_tree.to_string
  let final_description =
    list.fold(
      all_entities,
      from: entity.description <> "\n",
      with: fn(acc, entity) {
        acc <> "\n" <> "[" <> entity.id <> "]: /" <> entity.id
      },
    )

  html.div([attribute.class("flex flex-col gap-2 bg-amber-50 p-4")], [
    html.h1(
      [
        attribute.class(
          "border-b-4 border-red-200 text-2xl font-bold text-red-800",
        ),
      ],
      [html.text(entity.name)],
    ),
    html.p([], parser.parse(final_description)),
  ])
}
