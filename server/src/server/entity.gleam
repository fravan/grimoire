import gleam/dict
import gleam/dynamic/decode
import gleam/list
import server/database
import server/error
import sqlight

pub type EntityId =
  String

pub type EntityLinks =
  dict.Dict(EntityId, #(Entity, String))

pub type Entity {
  Entity(id: EntityId, name: String, description: String)
}

type LinkedEntity {
  LinkedEntity(id: EntityId, name: String, description: String, reason: String)
}

fn entity_row_decoder() -> decode.Decoder(Entity) {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use description <- decode.field(2, decode.string)
  decode.success(Entity(id:, name:, description:))
}

fn entity_link_row_decoder() -> decode.Decoder(LinkedEntity) {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use description <- decode.field(2, decode.string)
  use reason <- decode.field(3, decode.string)
  decode.success(LinkedEntity(id:, name:, description:, reason:))
}

pub fn get_all_entities(db: database.Connection) {
  let sql =
    "
    select id, name, description
    from entities
    order by name;
  "
  let assert Ok(rows) =
    sqlight.query(sql, on: db, with: [], expecting: entity_row_decoder())
  rows
}

pub fn get_entity_links(db: database.Connection, id: String) -> EntityLinks {
  let sql =
    "
  select e.id, e.name, e.description, coalesce(main.reason, link.reason) as reason
  from entities e
  left join entities_links main on main.main_entity_id = e.id
  left join entities_links link on link.linked_entity_id = e.id
  where main.linked_entity_id = ?1 or link.main_entity_id = ?1
  "
  let assert Ok(rows) =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(id)],
      expecting: entity_link_row_decoder(),
    )
  rows
  |> list.map(fn(linked_entity) {
    #(linked_entity.id, #(
      Entity(
        id: linked_entity.id,
        name: linked_entity.name,
        description: linked_entity.description,
      ),
      linked_entity.reason,
    ))
  })
  |> dict.from_list
}

pub fn get_entity_by_id(db: database.Connection, id: String) {
  let sql =
    "
    select id, name, description
    from entities
    where id = ?1;
  "
  let assert Ok(rows) =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(id)],
      expecting: entity_row_decoder(),
    )
  case rows {
    [item] -> Ok(item)
    _ -> Error(error.NotFound)
  }
}
