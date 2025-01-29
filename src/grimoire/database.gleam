import gleam/result
import grimoire/error
import sqlight

pub type Connection =
  sqlight.Connection

pub fn with_connection(name: String, f: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)
  let assert Ok(_) = sqlight.exec("pragma foreign_keys = on;", db)
  f(db)
}

pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, error.AppError) {
  sqlight.exec(
    "
    create table if not exists entities (
      id text primary key not null,
      name text not null,
      description text not null
    ) strict;

    create table if not exists entities_links (
      main_entity_id text not null,
      linked_entity_id text not null,
      reason text not null,

      primary key (main_entity_id, linked_entity_id),
      foreign key (main_entity_id)
        references entities (id),
      foreign key (linked_entity_id)
        references entities (id)
     ) strict;
    ",
    db,
  )
  |> result.map_error(error.SqlightError)
}
