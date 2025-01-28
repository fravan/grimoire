document.addEventListener("clear-selection", function (evt) {
  console.log(evt);
  document.querySelectorAll(".entity_link").forEach(function (node) {
    node.classList.remove("bg-orange-200");
    node.classList.add("bg-gray-200");
  });
});
