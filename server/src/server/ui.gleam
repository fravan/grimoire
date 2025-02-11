import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre_hx
import server/entity
import server/htmx
import server/parser
import shared/entities

pub fn layout(elements: List(Element(a))) {
  html.html([], [
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/assets/tailwind.min.css"),
      ]),
      html.script([attribute.src("/vendors/htmx-v2-0-4.min.js")], ""),
      html.script([attribute.src("/assets/client.min.mjs")], ""),
    ]),
    html.body(
      [lustre_hx.boost(True)],
      list.flatten([
        elements,
        [
          html.script(
            [],
            "const sse_livereload = new EventSource(\"sse_livereload\");
          sse_livereload.onmessage = (e) => {
            console.log(e);
            location.reload();
          };
          sse_livereload.onclose = () => {
            console.log(\"SSE closed\")
          };
          sse_livereload.onerror = (e) => {
            console.log(\"SSE Errored: \", e)
            sse_livereload.close();
          };
      ",
          ),
        ],
      ]),
    ),
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
      attribute.class(
        entities.entity_link_class <> " p-2 rounded hover:bg-gray-300",
      ),
      attribute.classes([
        #(entities.entity_highlighted_class, highlight_state == Highlighted),
        #(entities.entity_selected_class, highlight_state == Selected),
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
