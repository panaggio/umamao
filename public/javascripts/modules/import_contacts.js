$(document).ready(function () {

  // Unselect all contacts link
  $("#select-contacts a.remove_all").click(function () {
    $("#contacts-to-invite").empty().addClass("empty");
  });

  $("#contacts-to-invite .contact .remove").live("click", function () {
    $(this).closest(".contact").remove();
    if ($("#contacts-to-invite").is(":empty")) {
      $("#contacts-to-invite").addClass("empty");
    }
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

  var autocompleteTemplate = $.template(null,
    '<li class="autocomplete-entry">${name} ' +
    '<span class="desc">${email}</span></li>');

  var invitedContactTemplate = $.template(null,
    '<div class="contact">' + Utils.closeLink() +
    '<input type="hidden" name="emails[]" value="${email}" />' +
    '<div class="name">${name}</div>' +
    '<div class="email">${name}</div></div>');


  var ContactItem = function (contact) {
    this.data = contact;
    this.html = $.tmpl(autocompleteTemplate, contact);
  };

  ContactItem.prototype = {
    click: function () {
      var contactHtml = $.tmpl(invitedContactTemplate, this.data);

      $("#contacts-to-invite").
        removeClass("empty"). // The :empty selector didn't work.
        prepend(contactHtml);

      contactAutocomplete.clear();
    }
  };

  Utils.extend(ContactItem, Item);

  contactAutocomplete.processData = function (data) {
    var items = [];

    data.forEach(function (result) {
      items.push(new ContactItem(result));
    });

    return items;
  };

});
