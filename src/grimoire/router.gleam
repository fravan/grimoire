import gleam/list
import grimoire/entity
import grimoire/ui
import grimoire/web
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  // use ctx <- web.authenticate(req, ctx)
  use <- wisp.serve_static(req, under: "/", from: ctx.static_path)

  case wisp.path_segments(req) {
    [] -> home(ctx)
    [id] -> detail(ctx, id)
    _ -> wisp.not_found()
  }
}

fn home(ctx: web.Context) -> Response {
  ui.layout([
    html.div([attribute.class("flex flex-row gap-2")], [
      html.div(
        [attribute.class("flex gap-2")],
        entity.get_all_entities()
          |> list.map(fn(entity) { ui.entity_link(entity, ui.None, False) }),
      ),
      html.div([attribute.id("details")], [
        html.p([], [html.text("Select a character")]),
      ]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn detail(ctx: web.Context, id: String) -> Response {
  // TODO: Add a match on wether this is a HX boosted request or not
  case entity.get_entity_by_id(id) {
    Ok(entity) ->
      element.fragment([
        ui.entity_detail(entity),
        ui.entity_link(entity, ui.Selected, True),
        ..entity.get_entity_links(id)
        |> list.map(fn(linked_entity) {
          ui.entity_link(linked_entity, ui.Highlighted, True)
        })
      ])
      |> element.to_string_builder
      |> wisp.html_response(200)
      |> wisp.set_header("HX-Trigger", "clear-selection")
    _ -> wisp.response(404)
  }
}
