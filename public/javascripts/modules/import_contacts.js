$(document).ready(function () {

  // Unselect all contacts link
  $("#select-contacts a.remove_all").click(function () {
    $("#contacts-to-invite").addClass("empty");
    $("#contacts-to-invite .list").empty();
  });

  $("#contacts-to-invite .contact .remove").live("click", function () {
    $(this).closest(".contact").remove();
    if ($("#contacts-to-invite .list").is(":empty")) {
      $("#contacts-to-invite").addClass("empty");
    }
  });

  $("#import-contacts a").click(function () {
    var url = $(this).attr("href");
    var template =  $("#import-contacts .template").clone();
    template.find("a.continue").attr("href", url);
    Utils.modal({html: template.html()});
    return false;
  });

  var controls = $("#select-contacts .controls");

  if (controls.is(".waiting")) {
    // Need to wait for server to fetch external contacts

    var waitNotice = $("#select-contacts .wait-notice");

    var signalError = function () {
      Utils.showMessage(waitNotice.attr("data-error-message"), "error");
    };

    $.ajax({
      dataType: "json",
      error: signalError,
      success: function (data) {
        waitNotice.slideUp("slow", function () {
          waitNotice.remove();
          controls.removeClass("waiting");
          if (!data.success) {
            signalError();
          }
        });
      },
      type: "POST",
      url: waitNotice.attr("data-fetch-contacts-url")
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
    '<div class="email">${email}</div></div>');


  var ContactItem = function (contact) {
    this.data = contact;
    this.html = $.tmpl(autocompleteTemplate, contact);
  };

  ContactItem.prototype = {
    click: function () {
      var contactHtml = $.tmpl(invitedContactTemplate, this.data);

      $("#contacts-to-invite").removeClass("empty"); // The :empty selector didn't work.
      $("#contacts-to-invite .list").prepend(contactHtml);

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
