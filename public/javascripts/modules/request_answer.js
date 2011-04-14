function initUserAutocomplete(){

  // As the :empty pseudo-class isn't dynamic, we cannot
  // use it in our CSS. Instead, we use a regular "empty" class and
  // manage it in Javascript.
  var controls = $("#select-users");

  var userAutocomplete = new UserAutocomplete("#search-users",
                                                "#search-users-results");

  // Classifies the current question under topic named title.
  userAutocomplete.action = function (title) {
    $("#search-users").val(this.data.title);
    $(".invited_id").val(this.data.id);
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
        initUserAutocomplete();
      }
      else
        showMessage(data.message, "error");
    }
  };

});

