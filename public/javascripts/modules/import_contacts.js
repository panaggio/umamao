$(document).ready(function () {

  // Unselect all contacts link
  $("#select-contacts a.none").click(function () {
    $("#contacts-to-invite .contact").remove();
  });

  $("#contacts-to-invite .contact .remove").live("click", function () {
    $(this).closest(".contact").remove();
  });

  var controls = $("#select-contacts .controls");

  if (controls.is(".waiting")) {
    // Need to wait for server to fetch external contacts

    var signalError = function () {
      Utils.showMessage(controls.attr("data-error-message"), "error");
    };

    $.ajax({
      dataType: "json",
      error: signalError,
      success: function (data) {
        var waitNotice = $("#select-contacts .wait-notice");
        waitNotice.slideUp("slow", function () {
          waitNotice.remove();
          if (data.success) {
            controls.removeClass("waiting");
          } else {
            controls.remove();
            signalError();
          }
        });
      },
      type: "POST",
      url: controls.attr("data-fetch-contacts-url")
    });
  }

  var contactAutocomplete = new AutocompleteBox("#search-contacts",
                                                "#search-contacts-results");
});
