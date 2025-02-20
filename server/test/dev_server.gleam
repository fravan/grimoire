import dev_server/live_reload
import dev_server/logging
import dev_server/server_run
import dev_server/watcher.{type WatchMsg}
import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/string_tree
import mist

type SSEMessage {
  Reload
  Down(process.ProcessDown)
}

pub fn main() {
  let watch_subject = process.new_subject()
  let assert Ok(lr) = live_reload.start()
  let assert Ok(_) = watcher.start(watch_subject)
  let _ = server_run.start_server()

  let assert Ok(_) =
    fn(req: Request(mist.Connection)) -> Response(mist.ResponseData) {
      case request.path_segments(req) {
        ["sse_livereload"] -> {
          mist.server_sent_events(
            request: req,
            initial_response: response.new(200),
            init: fn() {
              let subj = process.new_subject()
              let monitor = process.monitor_process(process.self())
              live_reload.register_client(lr, subj)

              let selector =
                process.new_selector()
                |> process.selecting(subj, fn(_msg) { Reload })
                |> process.selecting_process_down(monitor, Down)

              actor.Ready(subj, selector)
            },
            loop: fn(message, conn, state) {
              case message {
                Reload -> {
                  let event = mist.event(string_tree.from_string("reload"))
                  case mist.send_event(conn, event) {
                    Ok(_) -> {
                      logging.log_debug("Successfully sent SSE to client")
                      actor.continue(state)
                    }
                    Error(_) -> {
                      logging.log_error("Could not send SSE to client")
                      actor.Stop(process.Normal)
                    }
                  }
                }
                Down(_) -> {
                  logging.log_debug("Client has disconnected")
                  live_reload.unregister_client(lr, state)
                  actor.Stop(process.Normal)
                }
              }
            },
          )
        }
        _ -> {
          let internal_error =
            response.new(500)
            |> response.set_body(mist.Bytes(bytes_tree.new()))

          let assert Ok(req) = mist.read_body(req, 100 * 1024 * 1024)
          Request(..req, port: option.Some(3000))
          |> httpc.send_bits
          |> result.map(response.map(_, maybe_inject_sse))
          |> result.map(response.map(_, bytes_tree.from_bit_array))
          |> result.map(response.map(_, mist.Bytes))
          |> result.unwrap(internal_error)
        }
      }
    }
    |> mist.new
    |> mist.port(1234)
    |> mist.start_http

  listen_to_watcher(watch_subject, lr)
}

fn listen_to_watcher(watch_subject: Subject(WatchMsg), live_reload) {
  let msg = process.receive_forever(watch_subject)
  case msg {
    watcher.Trigger -> {
      case server_run.reload_server_code() {
        Ok(_) -> {
          live_reload.trigger_clients(live_reload)
        }
        Error(msg) -> {
          logging.log_error("Error while reloading server code : " <> msg)
        }
      }
    }
  }
  listen_to_watcher(watch_subject, live_reload)
}

fn maybe_inject_sse(response: BitArray) {
  case bit_array.to_string(response) {
    Ok(str) -> bit_array.from_string(inject(str))
    Error(_) -> response
  }
}

fn inject(html: String) -> String {
  let script =
    "<script>
  const sse_livereload = new EventSource(\"sse_livereload\")
  sse_livereload.onmessage = (e) => {
    console.log(e)
    location.reload()
  }
  sse_livereload.onclose = () => {
    console.log(\"SSE closed\")
  }
  sse_livereload.onerror = (e) => {
    console.log(\"SSE Errored: \")
    console.log(e)
    sse_livereload.close()
  }
  window.addEventListener('beforeunload', () => {
    sse_livereload.close()
  })
  </script>"

  html
  |> string.replace("</head>", script <> "</head>")
}
