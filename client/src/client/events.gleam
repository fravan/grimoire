import gleam/list
import plinth/browser/document
import plinth/browser/element
import gleam/javascript/array

pub fn listen_to_clear_selection() {
  document.add_event_listener("clear-selection", fn (_) {
    document.query_selector_all(".entity-link")
    |> array.to_list
    |> list.each(fn (el) {
      element.remove_classes(el, ["highlighted", "selected"])
    })
    Nil
  })
}
