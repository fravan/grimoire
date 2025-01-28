import gleam/http/request
import lustre/attribute
import lustre/internals/vdom
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  boosted when_boosted: fn(Request) -> Response,
  basic when_basic: fn(Request) -> Response,
) {
  case request.get_header(req, "HX-Request") {
    Ok(_) -> when_boosted(req)
    _ -> when_basic(req)
  }
}

pub fn with_oob_swap(
  attributes: List(vdom.Attribute(b)),
  swap: Bool,
) -> List(vdom.Attribute(b)) {
  case swap {
    True -> [attribute.attribute("hx-swap-oob", "true"), ..attributes]
    False -> attributes
  }
}
