import server/database

pub type Context {
  Context(db: database.Connection, static_path: String)
}
