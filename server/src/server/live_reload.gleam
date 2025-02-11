import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/io
import gleam/list
import gleam/otp/actor

pub fn start() {
  actor.start_spec(actor.Spec(
    init: fn() {
      let actor_subject = process.new_subject()
      let selector =
        process.new_selector()
        |> process.selecting(actor_subject, function.identity)

      actor.Ready([], selector)
    },
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

fn loop_actor(message: Message, state: List(Subject(ClientMessage))) {
  case message {
    ClientConnected(client) -> {
      io.debug("[LR] Client connected")
      actor.continue([client, ..state])
    }
    ClientDisconnected(client) -> {
      io.debug("[LR] Client disconnected")
      actor.continue(state |> list.filter(fn(c) { c != client }))
    }
    TriggerClients -> {
      io.debug("[LR] Triggering clients")
      state
      |> list.each(fn(client) { process.send(client, Reload) })
      actor.continue(state)
    }
  }
}
