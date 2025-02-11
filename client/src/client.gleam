import gleam/dynamic
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/int
import gleam/javascript/promise
import gleam/json
import gleam/result
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/browser/document
import plinth/browser/element as browser_element
import rsvp

pub fn main() {
  let initial_model = read_initial_model()

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", initial_model)
  Nil
}

fn read_initial_model() {
  case
    document.query_selector("#model")
    |> result.map(browser_element.inner_text)
  {
    Ok(json_string) ->
      json.parse(json_string, decode.string) |> result.unwrap("")
    Error(_) -> ""
  }
}

pub type Model {
  Model(is_loading: Bool, quote: String)
}

fn init(initial_model: String) -> #(Model, Effect(Msg)) {
  #(Model(is_loading: False, quote: initial_model), effect.none())
}

pub type Msg {
  UserAskedQuote
  QuoteLoaded(Result(String, rsvp.Error))
}

fn update(m: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAskedQuote -> #(Model(..m, is_loading: True), get_quote())
    QuoteLoaded(Ok(quote)) -> #(Model(quote:, is_loading: False), effect.none())
    QuoteLoaded(Error(_)) -> #(
      Model(quote: "Error occured", is_loading: False),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("flex flex-col gap-12")], [
    button(
      case model.is_loading {
        False -> []
        True -> [attribute.disabled(True)]
      },
      case model.is_loading {
        False -> [html.text("Fetch a new quote")]
        True -> [html.text("Fetching…")]
      },
      UserAskedQuote,
    ),
    html.p([], [html.text(model.quote)]),
  ])
}

fn button(attributes, elements, on_click_msg: a) -> element.Element(a) {
  html.button(
    [
      event.on_click(on_click_msg),
      class(
        "bg-red-600 text-white text-semibold rounded-lg "
        <> "hover:bg-red-800 hover:enabled:cursor-pointer px-2 py-1 "
        <> "focus-visible:outline-none focus-visible:ring-2 "
        <> "focus-visible:ring-red-500 focus-visible:ring-offset-2 "
        <> "disabled:bg-gray-500",
      ),
      ..attributes
    ],
    elements,
  )
}

fn get_quote() -> Effect(Msg) {
  let url = "/api/quotes"
  let handler = rsvp.expect_json(decode_quote(), QuoteLoaded)
  rsvp.get(url, handler)
}

fn decode_quote() {
  use quote <- decode.field("content", decode.string)

  decode.success(quote)
}
