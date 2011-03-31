// ignore/unignore topics
// TODO: merge with follow_link and email_subscription.js,
// if possible
$(document).ready(function() {
  Utils.clickObject(".ignore_link", function () {
    var link = $(this);

    return {
      success: function (data) {
        Utils.toggleIgnoreLink(link);
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          window.location = "/users/login";
        }
      },

      type: "POST"
    };
  });
});
