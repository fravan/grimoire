import envoy
import gleam/erlang/process
import gleam/function
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/otp/actor
import gleam/result
import gleam/string_tree
import mist
import radiate
import server/database
import server/live_reload
import server/router
import server/web
import wisp
import wisp/wisp_mist

const db_name = "grimoire.sqlite3"

type SSEMessage {
  Reload
  Down(process.ProcessDown)
}

pub fn main() {
  let assert Ok(lr) = live_reload.start()

  let _ =
    radiate.new()
    |> radiate.add_dir("src/server")
    |> radiate.on_reload(fn(_, _) {
      io.debug("Triggering clients")
      live_reload.trigger_clients(lr)
      Nil
    })
    |> radiate.start()

  wisp.configure_logger()

  let port = load_port()
  let secret_key_base = load_application_secret()
  let assert Ok(priv) = wisp.priv_directory("server")
  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

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
                      io.debug("Successfully sent SSE to client")
                      actor.continue(state)
                    }
                    Error(_) -> {
                      io.debug("Could not send SSE to client")
                      actor.Stop(process.Normal)
                    }
                  }
                }
                Down(_) -> {
                  io.debug("Client has disconnected")
                  live_reload.unregister_client(lr, state)
                  actor.Stop(process.Normal)
                }
              }
            },
          )
        }
        _ ->
          wisp_mist.handler(
            fn(req) {
              use db <- database.with_connection(db_name)
              let ctx = web.Context(db:, static_path: priv <> "/static")
              router.handle_request(req, ctx)
            },
            secret_key_base,
          )(req)
      }
    }
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn load_application_secret() -> String {
  envoy.get("APP_SECRET")
  |> result.unwrap(wisp.random_string(64))
}

fn load_port() -> Int {
  envoy.get("APP_PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
