import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import jot.{type Container, type Document, type Inline}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre_hx

/// From text to HTML, with custom changes
pub fn parse(text: String) {
  text
  |> jot.parse
  |> document_to_html
}

type Refs {
  Refs(urls: Dict(String, String))
}

type GeneratedHtml(a) =
  List(Element(a))

fn document_to_html(document: Document) -> List(Element(a)) {
  containers_to_html(document.content, Refs(document.references), [])
}

fn containers_to_html(
  containers: List(Container),
  refs: Refs,
  html: GeneratedHtml(a),
) {
  case containers {
    [] -> list.reverse(html)
    [container, ..rest] -> {
      let html = container_to_html(html, container, refs)
      containers_to_html(rest, refs, html)
    }
  }
}

fn container_to_html(
  html: GeneratedHtml(a),
  container: Container,
  refs: Refs,
) -> GeneratedHtml(a) {
  case container {
    jot.ThematicBreak -> [html.hr([]), ..html]
    jot.Paragraph(_attrs, inlines) -> [
      html.p([], inlines_to_html([], inlines, refs)),
      ..html
    ]
    jot.Codeblock(_attrs, language, content) -> {
      let code_attrs = case language {
        Some(lang) -> [attribute.class("language-" <> lang)]
        None -> []
      }
      [html.pre([], [html.code(code_attrs, [html.text(content)])]), ..html]
    }
    jot.Heading(_attrs, level, inlines) -> {
      let heading_element = case level {
        1 -> html.h2([], inlines_to_html([], inlines, refs))
        2 -> html.h3([], inlines_to_html([], inlines, refs))
        3 -> html.h4([], inlines_to_html([], inlines, refs))
        4 -> html.h5([], inlines_to_html([], inlines, refs))
        _ -> html.h6([], inlines_to_html([], inlines, refs))
      }
      [heading_element, ..html]
    }
  }
}

fn inlines_to_html(
  html: GeneratedHtml(a),
  inlines: List(Inline),
  refs: Refs,
) -> GeneratedHtml(a) {
  case inlines {
    [] -> list.reverse(html)
    [inline, ..rest] -> {
      inlines_to_html([inline_to_html(inline, refs), ..html], rest, refs)
    }
  }
}

fn inline_to_html(inline: Inline, refs: Refs) {
  case inline {
    jot.Linebreak -> html.br([])
    jot.Text(text) -> html.text(text)
    jot.Strong(inlines) -> html.strong([], inlines_to_html([], inlines, refs))
    jot.Emphasis(inlines) -> html.em([], inlines_to_html([], inlines, refs))
    jot.Link(inlines, destination) -> {
      // This is where the fun starts
      case destination {
        jot.Url(url) ->
          html.a([attribute.href(url)], inlines_to_html([], inlines, refs))
        jot.Reference(id) ->
          case dict.get(refs.urls, id) {
            Ok(url) ->
              html.a(
                [
                  lustre_hx.target(lustre_hx.CssSelector("#details")),
                  attribute.href(url),
                ],
                inlines_to_html([], inlines, refs),
              )
            _ -> html.a([], inlines_to_html([], inlines, refs))
          }
      }
    }
    jot.Image(inlines, destination) ->
      html.img([
        attribute.src(destination_to_attribute(destination, refs)),
        attribute.alt(take_inline_text(inlines, "")),
      ])
    jot.Code(content) -> html.code([], [html.text(content)])
    jot.Footnote(_reference) -> html.text("Footnot is not implemented yet")
  }
}

fn destination_to_attribute(destination: jot.Destination, refs: Refs) {
  case destination {
    jot.Url(url) -> url
    jot.Reference(id) ->
      case dict.get(refs.urls, id) {
        Ok(url) -> url
        _ -> ""
      }
  }
}

fn take_inline_text(inlines: List(jot.Inline), acc: String) {
  case inlines {
    [] -> acc
    [first, ..rest] ->
      case first {
        jot.Text(text) | jot.Code(text) -> take_inline_text(rest, acc <> text)
        jot.Strong(inlines) | jot.Emphasis(inlines) ->
          take_inline_text(list.append(inlines, rest), acc)
        jot.Link(nested, _) | jot.Image(nested, _) -> {
          let acc = take_inline_text(nested, acc)
          take_inline_text(rest, acc)
        }
        jot.Linebreak | jot.Footnote(_) -> {
          take_inline_text(rest, acc)
        }
      }
  }
}
