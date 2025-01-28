import envoy
import gleam/erlang/process
import gleam/int
import gleam/result
import grimoire/router
import grimoire/web
import mist
import radiate
import wisp
import wisp/wisp_mist

// const db_name = "grimoire.sqlite3"

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir("src/grimoire")
    |> radiate.start()

  wisp.configure_logger()

  let port = load_port()
  let secret_key_base = load_application_secret()
  let assert Ok(priv) = wisp.priv_directory("grimoire")
  // let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  let handle_request = fn(req) {
    // use db <- database.with_connection(db_name)
    let ctx = web.Context(user_id: 0, static_path: priv <> "/static")
    router.handle_request(req, ctx)
  }

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn load_application_secret() -> String {
  envoy.get("APPLICATION_SECRET")
  |> result.unwrap("27434b28994f498182d459335258fb6e")
}

fn load_port() -> Int {
  envoy.get("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
