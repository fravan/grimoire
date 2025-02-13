import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import mist
import radiate
import server/database
import server/router
import server/web
import wisp
import wisp/wisp_mist

const db_name = "grimoire.sqlite3"

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir("src/server")
    |> radiate.on_reload(fn(_, _) {
      io.debug("Triggering clients")
      Nil
    })
    |> radiate.start()

  wisp.configure_logger()

  let port = load_port()
  let secret_key_base = load_application_secret()
  let assert Ok(priv) = wisp.priv_directory("server")
  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  let assert Ok(_) =
    wisp_mist.handler(
      fn(req) {
        use db <- database.with_connection(db_name)
        let ctx = web.Context(db:, static_path: priv <> "/static")
        router.handle_request(req, ctx)
      },
      secret_key_base,
    )
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
