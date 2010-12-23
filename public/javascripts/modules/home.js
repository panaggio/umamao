// Topic suggestion widget
Utils.clickObject("#topic-suggestions a.follow_link", function () {
  var suggestionsDiv = $("#topic-suggestions");

  return {

    data: {suggestion: true},

    success: function (data) {
      suggestionsDiv.replaceWith(data.suggestions);
    },

    type: "POST"

  };

});
