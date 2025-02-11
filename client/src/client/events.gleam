import gleam/javascript/array
import gleam/list
import plinth/browser/document
import plinth/browser/dom_token_list
import plinth/browser/element
import shared/entities
import shared/htmx_events

pub fn listen_to_clear_selection() {
  document.add_event_listener(htmx_events.clear_selection, fn(_) {
    document.query_selector_all("." <> entities.entity_link_class)
    |> array.to_list
    |> list.each(fn(el) {
      let class_list = element.class_list(el)
      dom_token_list.remove(
        class_list,
        array.from_list([
          entities.entity_selected_class,
          entities.entity_highlighted_class,
        ]),
      )
    })
    Nil
  })
}
