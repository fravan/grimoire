import gleam/dict
import gleam/list
import gleam/option
import gleam/string
import gleam/string_tree
import server/entity
import server/htmx
import server/ui
import server/web
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
    [] -> home(ctx, option.None)
    [id] -> detail(req, ctx, id)
    _ -> wisp.not_found()
  }
}

fn home(
  ctx: web.Context,
  selected_entity: option.Option(entity.Entity),
) -> Response {
  let all_entities = entity.get_all_entities(ctx.db)
  let links = case selected_entity {
    option.Some(x) -> entity.get_entity_links(ctx.db, x.id)
    _ -> dict.new()
  }
  ui.layout([
    html.div([attribute.class("flex flex-row gap-2")], [
      html.div(
        [attribute.class("flex gap-2")],
        all_entities
          |> list.map(fn(entity) {
            let highlight_state = case selected_entity {
              option.Some(x) if x.id == entity.id -> ui.Selected
              option.Some(_) ->
                case dict.has_key(links, entity.id) {
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
          option.Some(x) -> ui.entity_detail(x, all_entities)
          _ -> html.p([], [html.text("Select a character")])
        },
      ]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn detail(req: Request, ctx: web.Context, id: String) -> Response {
  htmx.handle_request(
    req,
    boosted: fn(_) { boosted_details(ctx, id) },
    basic: fn(_) {
      home(ctx, entity.get_entity_by_id(ctx.db, id) |> option.from_result)
    },
  )
}

fn boosted_details(ctx: web.Context, id: String) -> Response {
  let all_entities = entity.get_all_entities(ctx.db)
  case entity.get_entity_by_id(ctx.db, id) {
    Ok(entity) ->
      [
        ui.entity_detail(entity, all_entities),
        ui.entity_link(entity, ui.Selected, True),
        ..entity.get_entity_links(ctx.db, id)
        |> dict.map_values(fn(_key, value) {
          let #(entity, _reason) = value
          entity
        })
        |> dict.values
        |> list.map(fn(linked_entity) {
          ui.entity_link(linked_entity, ui.Highlighted, True)
        })
      ]
      |> list.map(element.to_string_builder)
      |> string_tree.join("")
      |> wisp.html_response(200)
      |> wisp.set_header("HX-Trigger", "clear-selection")
    _ -> wisp.response(404)
  }
}
