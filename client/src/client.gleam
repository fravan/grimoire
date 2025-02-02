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
  let assert Ok(json_string) =
    document.query_selector("#model")
    |> result.map(browser_element.inner_text)

  let initial_model =
    json.parse(json_string, decode.int)
    |> result.unwrap(0)

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", initial_model)
  Nil
}

pub type Model =
  Int

fn init(initial_model: Int) -> #(Model, Effect(Msg)) {
  #(initial_model, effect.none())
}

pub type Msg {
  Increment
  Decrement
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Increment -> #(model + 1, effect.none())
    Decrement -> #(model - 1, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("flex flex-col gap-12")], [
    button("Decrement", Decrement),
    html.p([], [html.text(int.to_string(model))]),
    button("Increment", Increment),
  ])
}

fn button(text: String, on_click_msg: a) -> element.Element(a) {
  html.button(
    [
      event.on_click(on_click_msg),
      class(
        "bg-red-600 text-white text-semibold rounded-lg "
        <> "hover:bg-red-800 px-2 py-1 "
        <> "focus-visible:outline-none focus-visible:ring-2 "
        <> "focus-visible:ring-red-500 focus-visible:ring-offset-2",
      ),
    ],
    [html.text(text)],
  )
}
