function initUserAutocomplete(){

  // As the :empty pseudo-class isn't dynamic, we cannot
  // use it in our CSS. Instead, we use a regular "empty" class and
  // manage it in Javascript.
  var controls = $("#select-users");

  var userAutocomplete = new UserAutocompleteBox("#search-users",
                                                "#search-users-results");


  var autocompleteTemplate = $.template(null,
    '<li class="autocomplete-entry">${name} ' +
    '<span class="desc">${email}</span></li>');

  var UserItem = function (user) {
    this.data = user;
    this.html = $.tmpl(autocompleteTemplate, user);
  };

  UserItem.prototype = {
    click: function () {
      userAutocomplete.clear();
      $("#search-users").val(this.data.name);
      $(".invited_id").val(this.data.id);
    }
  };

  Utils.extend(UserItem, Item);

  userAutocomplete.processData = function (data) {
    var items = [];

    data.forEach(function (result) {
      items.push(new UserItem(result));
    });

    return items;
  };
  
  // We should enable/disable the "add" button as well.
  // TODO: maybe we should incorporate buttons in the AutocompleteBox as well.
  userAutocomplete.enable = function () {
    controls.find("input").removeAttr("disabled");
    AutocompleteBox.prototype.enable.call(this);
  };

  userAutocomplete.disable = function () {
    controls.find("input").attr("disabled", "true");
    AutocompleteBox.prototype.disable.call(this);
  };


}

// Button to add the typed email to the list.
Utils.clickObject(".invite-button", function () {
  return {
    success: function(data) {
      Utils.showMessage(data.message, "notice");
      $.colorbox.close();
    }
  };

});

// Button to add the typed email to the list.
Utils.clickObject(".request-answer-button", function () {
  return {
    url: $(this).attr("href"),
    dataType: "json",
    type: "GET",
    success: function(data) {
      if(data.success){
        Utils.modal({html : data.html});
        initAutocompleteUser();
      }
      else
        showMessage(data.message, "error");
    }
  };

});

