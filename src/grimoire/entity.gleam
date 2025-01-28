import gleam/dict
import gleam/list

pub type Entity {
  Entity(
    id: String,
    name: String,
    description: String,
    links: dict.Dict(String, String),
  )
}

pub fn get_all_entities() {
  [
    Entity(
      "zz",
      "Zelda",
      "Zelda is (bb)[Link]'s princess to be saved",
      dict.new() |> dict.insert("bb", "Link to Link"),
    ),
    Entity(
      "bb",
      "Link",
      "Link is (zz)[Zelda]'s knight",
      dict.new() |> dict.insert("zz", "Link to zelda"),
    ),
    Entity("aa", "Sanderson", "WTF is Sanderson doing here?", dict.new()),
  ]
}

pub fn get_entity_by_id(id: String) {
  get_all_entities()
  |> list.find(fn(entity) { entity.id == id })
}
