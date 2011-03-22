$(document).ready(function () {

  // As the :empty pseudo-class isn't dynamic, we cannot
  // use it in our CSS. Instead, we use a regular "empty" class and
  // manage it in Javascript.

  var controls = $("#select-contacts .controls");

  var invitationsLeft = controls.find(".invitations-left").
                      attr("data-invitations-left");

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

  var invitedContactTemplate = $.template(null,
    '<div class="contact">' + Utils.closeLink() +
    '<input type="hidden" name="emails[]" value="${email}" />' +
    '<div class="name">${name}</div>' +
    '<div class="email">${email}</div></div>');

  // Return true if more contacts can be added.
  var canInvite = function () {
    return invitationsLeft != "unlimited" &&
      invitationsLeft > $("#contacts-to-invite .list .contact").size();
  };

  // Check whether the user can still invite others.
  var refreshInvitationCountStatus = function () {
    if (canInvite()) {
      contactAutocomplete.enable();
    } else {
      contactAutocomplete.disable();
    }
  };

  // Add a contact to the invitation list.
  var addContactToList = function (contact) {
    $("#contacts-to-invite").removeClass("empty");
    $("#contacts-to-invite .list").
      prepend($.tmpl(invitedContactTemplate, contact));
    refreshInvitationCountStatus();
  };

  var contactAutocomplete = new AutocompleteBox("#search-contacts",
                                                "#search-contacts-results");

  // Add input from the autocomplete box to the invitation list directly.
  var addInputToList = function () {
    var email = contactAutocomplete.input.val().trim();
    if (email != "") {
      addContactToList({name: "", email: email});
      contactAutocomplete.clear();
    }
  };

  // Button to add the typed email to the list.
  controls.find(".add-contact").click(function () {
    if (contactAutocomplete.isActive &&
        contactAutocomplete.input.val().trim())
      addInputToList();
    return false;
  });

  var autocompleteTemplate = $.template(null,
    '<li class="autocomplete-entry">${name} ' +
    '<span class="desc">${email}</span></li>');

  var ContactItem = function (contact) {
    this.data = contact;
    this.html = $.tmpl(autocompleteTemplate, contact);
  };

  ContactItem.prototype = {
    click: function () {
      addContactToList(this.data);
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

  contactAutocomplete.returnDefault = addInputToList;


  // We should enable/disable the "add" button as well.
  // TODO: maybe we should incorporate buttons in the AutocompleteBox as well.
  contactAutocomplete.enable = function () {
    controls.find("input").removeAttr("disabled");
    AutocompleteBox.prototype.enable.call(this);
  };

  contactAutocomplete.disable = function () {
    controls.find("input").attr("disabled", "true");
    AutocompleteBox.prototype.disable.call(this);
  };


  // Check whether to send the value of the email box to the server.
  $("#select-contacts-form").submit(function () {
    if (!contactAutocomplete.input.is(".inactive") && canInvite()) {
      var typedEmail = $('<input name="emails[]" type="hidden" />').
        attr("value", contactAutocomplete.input.val());
      $("#select-contacts-form").append(typedEmail);
    }
  });

  // Unselect all contacts link
  $("#select-contacts a.remove_all").click(function () {
    $("#contacts-to-invite").addClass("empty");
    $("#contacts-to-invite .list").empty();
    refreshInvitationCountStatus();
  });

  // Remove individual contacts
  $("#contacts-to-invite .contact .remove").live("click", function () {
    $(this).closest(".contact").remove();
    if ($("#contacts-to-invite .list").is(":empty")) {
      $("#contacts-to-invite").addClass("empty");
    }
    refreshInvitationCountStatus();
  });

  // Open a modal box when user clicks the import contact link
  $("#import-contacts a").click(function () {
    var url = $(this).attr("href");
    var template =  $("#import-contacts .template").clone();
    template.find("a.continue").attr("href", url);
    Utils.modal({html: template.html()});
    return false;
  });

});
