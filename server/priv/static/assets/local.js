document.addEventListener("clear-selection", function (evt) {
  document.querySelectorAll(".entity-link").forEach(function (node) {
    node.classList.remove("highlighted", "selected");
  });
});
