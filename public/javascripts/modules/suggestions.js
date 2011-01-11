// Suggestion widgets (users and topics). Interaction logic and ajax requests.

Utils.clickObject(".suggestions a.follow_link, .suggestions .refuse-suggestion a", function () {
  var li = $(this).closest("li");
  var suggestionsDiv = $(this).closest(".suggestions");

  return {

    data: {suggestion: true},

    success: function (data) {
      li.slideUp(800, function () {
        suggestionsDiv.replaceWith(data.suggestions);
      });
    },

    type: "POST"

  };

});
