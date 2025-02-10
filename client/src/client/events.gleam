import gleam/javascript/array
import gleam/list
import plinth/browser/document
import plinth/browser/dom_token_list
import plinth/browser/element

pub fn listen_to_clear_selection() {
  document.add_event_listener("clear-selection", fn(_) {
    document.query_selector_all(".entity-link")
    |> array.to_list
    |> list.each(fn(el) {
      let class_list = element.class_list(el)
      dom_token_list.remove(
        class_list,
        array.from_list(["highlighted", "selected"]),
      )
    })
    Nil
  })
}
