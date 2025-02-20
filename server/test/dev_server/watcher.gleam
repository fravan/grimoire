import dev_server/logging
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/erlang/charlist
import gleam/erlang/process.{type Subject, type Timer}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor.{type ErlangStartResult}

@external(erlang, "fs", "start_link")
fn fs_start_link(name: Atom, path: String) -> ErlangStartResult

@external(erlang, "fs", "subscribe")
fn fs_subscribe(name: Atom) -> Atom

pub type WatchMsg {
  Trigger
}

type State {
  State(debounce_timer: Option(Timer), watch_subject: Subject(WatchMsg))
}

fn do_loop(msg: Msg, state: State) {
  case msg {
    Unknown -> actor.continue(state)
    Updates(_) -> {
      case state.debounce_timer {
        Some(timer) -> {
          process.cancel_timer(timer)
          Nil
        }
        None -> Nil
      }
      // Watcher sends multiple events for a same save,
      // so we debounce it to avoid multiple builds in a very short time
      let timer = process.send_after(state.watch_subject, 50, Trigger)
      actor.continue(State(..state, debounce_timer: Some(timer)))
    }
  }
}

pub type Msg {
  Unknown
  Updates(#(String, List(FileEvent)))
}

pub type FileEvent {
  UnknownEvent
  Created
  Deleted
  Modified
  Closed
  Renamed
  Attribute
  Removed
}

fn erlang_string_to_string_decoder() {
  decode.new_primitive_decoder("ErlangString", fn(data) {
    coerce(data) |> charlist.to_string |> Ok
  })
}

/// Converts an atom to an event
fn atom_to_string_decoder() {
  let created = atom.create_from_string("created")
  let deleted = atom.create_from_string("deleted")
  let modified = atom.create_from_string("modified")
  let closed = atom.create_from_string("closed")
  let renamed = atom.create_from_string("renamed")
  let attrib = atom.create_from_string("attribute")
  let removed = atom.create_from_string("removed")

  decode.new_primitive_decoder("Atom", fn(data) {
    case atom.from_dynamic(data) {
      Ok(ev) if ev == created -> Ok(Created)
      Ok(ev) if ev == deleted -> Ok(Deleted)
      Ok(ev) if ev == modified -> Ok(Modified)
      Ok(ev) if ev == closed -> Ok(Closed)
      Ok(ev) if ev == renamed -> Ok(Renamed)
      Ok(ev) if ev == removed -> Ok(Removed)
      Ok(ev) if ev == attrib -> Ok(Attribute)
      Ok(_) -> Ok(UnknownEvent)
      Error(_) -> Ok(UnknownEvent)
    }
  })
}

@external(erlang, "dev_ffi", "identity")
fn coerce(value: a) -> b

pub fn start(watch_subject: Subject(WatchMsg)) {
  actor.start_spec(
    actor.Spec(init_timeout: 5000, loop: do_loop, init: fn() {
      let server_dir = "src/server"
      let atom = atom.create_from_string("fs_watcher_" <> server_dir)
      case fs_start_link(atom, server_dir) {
        Ok(_pid) -> {
          fs_subscribe(atom)
          let selectors =
            process.new_selector()
            |> process.selecting_anything(fn(msg) {
              let decoder = {
                use file_name <- decode.subfield(
                  [2, 0],
                  erlang_string_to_string_decoder(),
                )
                use events <- decode.subfield(
                  [2, 1],
                  decode.list(atom_to_string_decoder()),
                )
                decode.success(#(file_name, events))
              }
              case decode.run(msg, decoder) {
                Ok(stuff) -> Updates(stuff)
                Error(_) -> {
                  logging.log_error("Error occured while watching files")
                  Unknown
                }
              }
            })
          actor.Ready(State(None, watch_subject), selectors)
        }
        Error(_) -> {
          logging.log_error("Error occured while watching folder")
          actor.Failed("Err")
        }
      }
    }),
  )
}
