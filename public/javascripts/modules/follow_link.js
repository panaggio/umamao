// Follow/unfollow buttons
$(document).ready(function() {
  Utils.clickObject(".follow_link", function () {
    var link = $(this);

    return {
      success: function (data) {
        if ($("#sidebar .followers").size() > 0) {
          if (data.follower) {
            element = $(data.follower);
            element.hide();
            $("#sidebar .followers .friend_list").append(element);
            element.fadeIn("slow");
          }
          if (data.followers_count) {
            $("#sidebar .followers .count").text(data.followers_count);
          }
        }
        Utils.toggleFollowLink(link);
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          window.location = "/users/login";
        }
      },

      type: "POST"
    };
  });

  Utils.clickObject(".unfollow_link", function () {
    var link = $(this);

    return {
      success: function (data) {
        if ($("#sidebar .followers").size() > 0) {
          if (data.user_id) {
            var element = $("#sidebar .followers [data-user-id=" +
                            data.user_id + "]");
            element.fadeOut("slow", function () { element.remove(); });
          }
          if (data.followers_count) {
            $("#sidebar .followers .count").text(data.followers_count);
          }
        }
        Utils.toggleFollowLink(link);
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
