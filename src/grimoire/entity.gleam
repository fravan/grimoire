import gleam/dict
import gleam/list
import gleam/pair
import gleam/result

pub type Entity {
  Entity(id: String, name: String, description: String)
}

const entities = [
  #("zz", Entity("zz", "Zelda", "Zelda is (bb)[Link]'s princess to be saved")),
  #("bb", Entity("bb", "Link", "Link is (zz)[Zelda]'s knight")),
  #("aa", Entity("aa", "Sanderson", "WTF is Sanderson doing here?")),
]

const entities_links = [#("zz", ["bb"]), #("bb", ["zz"])]

pub fn get_all_entities() {
  entities |> list.map(pair.second)
}

pub fn get_entity_by_id(id: String) {
  dict.from_list(entities)
  |> dict.get(id)
}

pub fn get_entity_links(id: String) {
  dict.from_list(entities_links)
  |> dict.get(id)
  |> result.map(fn(ids) {
    ids |> list.map(get_entity_by_id) |> result.all |> result.unwrap([])
  })
  |> result.unwrap([])
}
