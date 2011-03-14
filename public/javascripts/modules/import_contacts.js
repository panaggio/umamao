$(document).ready(function () {
  $("#select-contacts a.all").click(function () {
    $("#imported-contacts input[type=checkbox]").attr("checked", "true");
  });

  $("#select-contacts a.none").click(function () {
    $("#imported-contacts input[type=checkbox]").attr("checked", "");
  });
});
