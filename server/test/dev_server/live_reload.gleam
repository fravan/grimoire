import dev_server/logging
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/set.{type Set}

pub fn start() {
  actor.start_spec(actor.Spec(
    init: fn() { actor.Ready(set.new(), process.new_selector()) },
    init_timeout: 500,
    loop: loop_actor,
  ))
}

pub fn register_client(live_reload_actor, client) {
  actor.send(live_reload_actor, ClientConnected(client))
}

pub fn unregister_client(live_reload_actor, client) {
  actor.send(live_reload_actor, ClientDisconnected(client))
}

pub fn trigger_clients(live_reload_actor) {
  actor.send(live_reload_actor, TriggerClients)
}

pub type ClientMessage {
  Reload
}

pub opaque type Message {
  ClientConnected(Subject(ClientMessage))
  ClientDisconnected(Subject(ClientMessage))
  TriggerClients
}

fn loop_actor(message: Message, state: Set(Subject(ClientMessage))) {
  case message {
    ClientConnected(client) -> {
      logging.log_debug("Client connected")
      actor.continue(set.insert(state, client))
    }
    ClientDisconnected(client) -> {
      logging.log_debug("Client disconnected")
      actor.continue(set.delete(state, client))
    }
    TriggerClients -> {
      logging.log_debug("Triggering client to reload")
      set.each(state, fn(client) { process.send(client, Reload) })
      actor.continue(state)
    }
  }
}
