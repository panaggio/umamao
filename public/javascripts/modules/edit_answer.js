$(document).ready(function () {
  if ($("textarea#answer-input").length > 0) {
    Utils.enableEditor("#answer-input", "answer-preview");
  }
});
