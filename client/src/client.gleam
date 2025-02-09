import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
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

pub fn main() {
  let initial_model = read_initial_model()

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", initial_model)
  Nil
}

fn read_initial_model() {
  case document.query_selector("#model")
    |> result.map(browser_element.inner_text) {
    Ok(json_string) -> json.parse(json_string, decode.string) |> result.unwrap("")
    Error(_) -> ""
  }
}

pub type Model {
  Model(
    is_loading: Bool,
    quote: String,
  )
}

fn init(initial_model: String) -> #(Model, Effect(Msg)) {
  #(Model(is_loading: False, quote: initial_model), effect.none())
}

pub type Msg {
  UserAskedQuote
  QuoteLoaded
}

fn update(m: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAskedQuote -> #(Model(..m, is_loading: True), effect.none())
    QuoteLoaded -> #(Model(..m, is_loading: False), effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("flex flex-col gap-12")], [
    button("Fetch a new quote", UserAskedQuote),
    html.p([], [html.text(model.quote)]),
  ])
}

fn button(text: String, on_click_msg: a) -> element.Element(a) {
  html.button(
    [
      event.on_click(on_click_msg),
      class(
        "bg-red-600 text-white text-semibold rounded-lg "
        <> "hover:bg-red-800 hover:cursor-pointer px-2 py-1 "
        <> "focus-visible:outline-none focus-visible:ring-2 "
        <> "focus-visible:ring-red-500 focus-visible:ring-offset-2",
      ),
    ],
    [html.text(text)],
  )
}
