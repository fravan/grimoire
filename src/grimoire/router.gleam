import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import grimoire/entity
import grimoire/htmx
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
    [] -> home(option.None)
    [id] -> detail(req, ctx, id)
    _ -> wisp.not_found()
  }
}

fn home(selected_entity: option.Option(entity.Entity)) -> Response {
  ui.layout([
    html.div([attribute.class("flex flex-row gap-2")], [
      html.div(
        [attribute.class("flex gap-2")],
        entity.get_all_entities()
          |> list.map(fn(entity) {
            let highlight_state = case selected_entity {
              option.Some(x) if x.id == entity.id -> ui.Selected
              option.Some(x) ->
                case dict.has_key(x.links, entity.id) {
                  True -> ui.Highlighted
                  False -> ui.None
                }
              _ -> ui.None
            }
            ui.entity_link(entity, highlight_state, False)
          }),
      ),
      html.div([attribute.id("details")], [
        case selected_entity {
          option.Some(x) -> ui.entity_detail(x)
          _ -> html.p([], [html.text("Select a character")])
        },
      ]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn detail(req: Request, _ctx: web.Context, id: String) -> Response {
  htmx.handle_request(req, boosted: fn(_) { boosted_details(id) }, basic: fn(_) {
    home(entity.get_entity_by_id(id) |> option.from_result)
  })
}

fn boosted_details(id: String) -> Response {
  case entity.get_entity_by_id(id) {
    Ok(entity) ->
      element.fragment([
        ui.entity_detail(entity),
        ui.entity_link(entity, ui.Selected, True),
        ..entity.links
        |> dict.map_values(fn(key, _value) { entity.get_entity_by_id(key) })
        |> dict.values
        |> result.all
        |> result.unwrap([])
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
