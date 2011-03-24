// Suggestion widgets (users and topics). Interaction logic and ajax requests.

Utils.clickObject(".suggestions a.follow_link, .suggestions .refuse-suggestion a", function () {
  var li = $(this).closest("li");
  var suggestionsDiv = $(this).closest(".suggestions");
  var isFollow = $(this).is(".follow_link");

  return {

    data: isFollow ? {suggestion: true} : {},

    success: function (data) {
      li.slideUp(800, function () {
        suggestionsDiv.replaceWith(data.suggestions);
        Utils.poshytipfy();
      });
    }

  };

});

// Workaroud to get .follow_link's to work properly
$('a[data-confirm], a[data-method], a[data-remote]').die("click.rails");
