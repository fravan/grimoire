import birl
import birl/duration
import gleam/http
import gleam/int
import gleam/string
import logging
import lustre/attribute
import lustre/element
import lustre/element/html
import server/web
import wisp.{type Request, type Response}

fn log_request(req: Request, handler: fn() -> Response) -> Response {
  let start = birl.now()
  let response = handler()
  let end = birl.now()

  [
    int.to_string(response.status),
    " ",
    string.uppercase(http.method_to_string(req.method)),
    " ",
    req.path,
    " ",
    case birl.difference(end, start) |> duration.blur {
      #(us, duration.MicroSecond) -> int.to_string(us) <> "us"
      #(ms, duration.MilliSecond) -> int.to_string(ms) <> "ms"
      #(s, duration.Second) -> int.to_string(s) <> "s"
      _ -> "way too slow"
    },
  ]
  |> string.concat
  |> logging.log(logging.Info, _)
  response
}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  let req = wisp.method_override(req)
  // use <- wisp.log_request(req)
  use <- log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_path)

  case wisp.path_segments(req) {
    [] -> home()
    _ -> wisp.not_found()
  }
}

fn home() -> Response {
  let content =
    html.div([attribute.class("p-2 flex text-center")], [
      html.p([attribute.class("p-4")], [
      html.text("Hello, world!")])]) |> page_scaffold("")

  wisp.response(200)
  |> wisp.html_body(content |> element.to_document_string_builder())
}

fn page_scaffold(content: element.Element(a), init_json: String) {
  html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.attribute("charset", "UTF-8")]),
      html.meta([
        attribute.attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
      html.title([], "Grimoire"),
      html.script(
        [attribute.src("/static/client.min.mjs"), attribute.type_("module")],
        "",
      ),
      html.script(
        [attribute.type_("application/json"), attribute.id("model")],
        init_json,
      ),
      html.link([
        attribute.href("/static/client.min.css"),
        attribute.rel("stylesheet"),
      ]),
    ]),
    html.body([], [html.div([attribute.id("app")], [content])]),
  ])
}
