$(document).ready(function () {

  // Select all contacts link
  $("#select-contacts a.all").click(function () {
    $("#imported-contacts input[type=checkbox]").attr("checked", "true");
  });

  // Unselect all contacts link
  $("#select-contacts a.none").click(function () {
    $("#imported-contacts input[type=checkbox]").attr("checked", "");
  });

  // Contact filter box
  $("#select-contacts .autocomplete").focus(function () {
    var input = $(this);
    input.attr("data-start-text", input.val()).val("").addClass("active");
  }).blur(function () {
    var input = $(this);
    input.val(input.attr("data-start-text")).removeClass("active");
  }).keyup(function () {
    var input = $(this);
    var re = new RegExp(Utils.escapeRegExp(input.val()), "i");
    $("#imported-contacts .contact").each(function () {
      if ($(this).find(".name").text().match(re)) {
        $(this).removeClass("no-match");
      } else {
        $(this).addClass("no-match");
      }
    });
  });
});
