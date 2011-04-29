// Subscribe/unsubscribe to notifications by email for topics' questions
$(document).ready(function() {
  Utils.clickObject("#toggle_email_subscription_link", function () {
    var link = $(this);

    return {
      success: function (data) {
        Utils.toggleEmailSubscriptionLink(link);
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          window.location = "/users/login";
        }
      }
    };
  });
});
