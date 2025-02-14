import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor

pub type Message {
  KillServer
  RestartServer
  SavePort(String)
}

pub fn start_server() {
  actor.start_spec(
    actor.Spec(loop: loop_runs, init_timeout: 500, init: fn() {
      let port = run_server()
      actor.Ready(Some(port), process.new_selector())
    }),
  )
}

pub fn restart(server: Subject(Message)) {
  process.send(server, KillServer)
}

fn loop_runs(msg: Message, current_port: Option(String)) {
  case msg {
    KillServer -> {
      case current_port {
        Some(port) -> {
          io.debug("[Server] closing port " <> port)
          io.debug(stop_server(port))
          actor.continue(None)
        }
        None -> actor.continue(None)
      }
    }
    RestartServer -> {
      io.debug("[Server] Some child process died, should start a new process?")
      actor.continue(current_port)
    }
    SavePort(port) -> {
      case current_port {
        Some(p) if p != port -> {
          io.debug(
            "[Server] a new port is to be saved, but a previous one still exists",
          )
          io.debug("New: " <> port <> " // Old: " <> p)
          stop_server(p)
          Nil
        }
        _ -> Nil
      }
      actor.continue(Some(port))
    }
  }
}

@external(erlang, "dev_ffi", "run_server")
fn run_server() -> String

@external(erlang, "dev_ffi", "stop_server")
fn stop_server(port: String) -> Bool
