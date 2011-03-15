$(document).ready(function () {

  // Unselect all contacts link
  $("#select-contacts a.none").click(function () {
    $("#contacts-to-invite .contact").remove();
  });

  $("#contacts-to-invite .contact .remove").live("click", function () {
    $(this).closest(".contact").remove();
  });

  var contactAutocomplete = new AutocompleteBox("#search-contacts",
                                                "#search-contacts-results");
});
