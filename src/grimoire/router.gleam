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
    [name] -> detail(ctx, name)
    _ -> wisp.not_found()
  }
}

fn home(ctx: web.Context) -> Response {
  ui.layout([
    html.div([attribute.class("flex flex-row gap-2")], [
      html.div([attribute.class("flex gap-2")], [
        ui.entity_link("Link", False, False),
        ui.entity_link("Zelda", False, False),
        ui.entity_link("Sanderson", False, False),
      ]),
      html.div([attribute.id("details")], [
        html.p([], [html.text("Select a character")]),
      ]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn detail(ctx: web.Context, name: String) -> Response {
  // TODO: Add a match on wether this is a HX boosted request or not
  element.fragment([
    ui.entity_detail(name, "This is " <> name <> " page"),
    ui.entity_link(name, True, True),
  ])
  |> element.to_string_builder
  |> wisp.html_response(200)
}
