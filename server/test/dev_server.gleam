import dev_server/client_registry.{type ClientRegistry}
import dev_server/logging
import dev_server/proxy
import dev_server/server_run
import dev_server/watcher
import gleam/erlang/process.{type Subject}

pub fn main() {
  let clients = client_registry.start()
  let watch_subject = process.new_subject()
  let assert Ok(_) = watcher.start(watch_subject)
  let _ = server_run.start_server()

  let assert Ok(_) = proxy.start_http(clients)

  listen_to_watcher(watch_subject, clients)
}

fn listen_to_watcher(
  watch_subject: Subject(watcher.Message),
  clients: ClientRegistry,
) {
  let msg = process.receive_forever(watch_subject)
  case msg {
    watcher.FilesChanged -> {
      case server_run.reload_server_code() {
        Ok(_) -> {
          client_registry.trigger(clients)
        }
        Error(msg) -> {
          logging.log_error("Error while reloading server code : " <> msg)
        }
      }
    }
  }
  listen_to_watcher(watch_subject, clients)
}
