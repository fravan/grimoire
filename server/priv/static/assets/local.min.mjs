(() => {
  // build/dev/javascript/prelude.mjs
  var List = class {
    static fromArray(array, tail) {
      let t = tail || new Empty();
      for (let i = array.length - 1; i >= 0; --i) {
        t = new NonEmpty(array[i], t);
      }
      return t;
    }
    [Symbol.iterator]() {
      return new ListIterator(this);
    }
    toArray() {
      return [...this];
    }
    // @internal
    atLeastLength(desired) {
      for (let _ of this) {
        if (desired <= 0) return true;
        desired--;
      }
      return desired <= 0;
    }
    // @internal
    hasLength(desired) {
      for (let _ of this) {
        if (desired <= 0) return false;
        desired--;
      }
      return desired === 0;
    }
    // @internal
    countLength() {
      let length3 = 0;
      for (let _ of this) length3++;
      return length3;
    }
  };
  function prepend(element, tail) {
    return new NonEmpty(element, tail);
  }
  function toList(elements, tail) {
    return List.fromArray(elements, tail);
  }
  var ListIterator = class {
    #current;
    constructor(current) {
      this.#current = current;
    }
    next() {
      if (this.#current instanceof Empty) {
        return { done: true };
      } else {
        let { head, tail } = this.#current;
        this.#current = tail;
        return { value: head, done: false };
      }
    }
  };
  var Empty = class extends List {
  };
  var NonEmpty = class extends List {
    constructor(head, tail) {
      super();
      this.head = head;
      this.tail = tail;
    }
  };

  // build/dev/javascript/gleam_javascript/gleam_javascript_ffi.mjs
  function reduceRight(thing, acc, fn) {
    return thing.reduceRight(fn, acc);
  }

  // build/dev/javascript/gleam_javascript/gleam/javascript/array.mjs
  function to_list(items) {
    return reduceRight(
      items,
      toList([]),
      (list, item) => {
        return prepend(item, list);
      }
    );
  }

  // build/dev/javascript/gleam_stdlib/dict.mjs
  var tempDataView = new DataView(new ArrayBuffer(8));
  var SHIFT = 5;
  var BUCKET_SIZE = Math.pow(2, SHIFT);
  var MASK = BUCKET_SIZE - 1;
  var MAX_INDEX_NODE = BUCKET_SIZE / 2;
  var MIN_ARRAY_NODE = BUCKET_SIZE / 4;
  var unequalDictSymbol = Symbol();

  // build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
  var unicode_whitespaces = [
    " ",
    // Space
    "	",
    // Horizontal tab
    "\n",
    // Line feed
    "\v",
    // Vertical tab
    "\f",
    // Form feed
    "\r",
    // Carriage return
    "\x85",
    // Next line
    "\u2028",
    // Line separator
    "\u2029"
    // Paragraph separator
  ].join("");
  var trim_start_regex = new RegExp(`^[${unicode_whitespaces}]*`);
  var trim_end_regex = new RegExp(`[${unicode_whitespaces}]*$`);

  // build/dev/javascript/gleam_stdlib/gleam/list.mjs
  function each(loop$list, loop$f) {
    while (true) {
      let list = loop$list;
      let f = loop$f;
      if (list.hasLength(0)) {
        return void 0;
      } else {
        let first$1 = list.head;
        let rest$1 = list.tail;
        f(first$1);
        loop$list = rest$1;
        loop$f = f;
      }
    }
  }

  // build/dev/javascript/plinth/document_ffi.mjs
  function querySelectorAll(query) {
    return Array.from(document.querySelectorAll(query));
  }
  function addEventListener(type, listener) {
    return document.addEventListener(type, listener);
  }

  // build/dev/javascript/plinth/element_ffi.mjs
  function innerText(element) {
    return element.innerText;
  }
  function addClass(element, classnames) {
    element.classList.add(...classnames);
  }
  function removeClass(element, classnames) {
    element.classList.remove(...classnames);
  }
  function toggleClass(element, classname, predicate) {
    console.log("toggle class", classname, predicate);
    element.classList.toggle(classname, predicate ?? true);
  }
  function replaceClass(element, from, to) {
    element.classList.replace(from, to);
  }

  // build/dev/javascript/plinth/plinth/browser/element.mjs
  function add_class(element, classname) {
    return addClass(element, toList([classname]));
  }
  function toggle_class(element, classname) {
    return toggleClass(element, classname, true);
  }

  // build/dev/javascript/client/client/events.mjs
  function listen_to_clear_selection() {
    return addEventListener(
      "clear-selection",
      (_) => {
        let _pipe = querySelectorAll(".entity-link");
        let _pipe$1 = to_list(_pipe);
        each(
          _pipe$1,
          (el) => {
            removeClass(el, toList(["highlighted", "selected"]));
            add_class(el, "toto");
            addClass(el, toList(["tutu", "and-tutu-too"]));
            toggle_class(el, "tata");
            toggleClass(
              el,
              "ME",
              innerText(el) === "Sanderson"
            );
            return replaceClass(el, "tutu", "tutu-replaced");
          }
        );
        return void 0;
      }
    );
  }

  // build/dev/javascript/client/client.mjs
  function main() {
    return listen_to_clear_selection();
  }
  main();
  main();
  main();
})();
