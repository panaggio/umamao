// Topic suggestion widget

Utils.clickObject("#topic-suggestions a.follow_link, #topic-suggestions .refuse-suggestion a", function () {
  var li = $(this).closest("li");
  var suggestionsDiv = $("#topic-suggestions");

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
