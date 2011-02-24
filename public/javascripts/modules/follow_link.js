// Follow/unfollow buttons
$(document).ready(function() {
  Utils.clickObject(".follow_link", function () {
    var link = $(this);

    // The type of what's being followed
    var entryType = link.attr("data-entry-type");

    return {
      success: function (data) {
        var followers =
          $("#sidebar .followers[data-entry-type=" + entryType + "]");
        if (followers.size() > 0) {
          if (data.follower && followers.find(".friend_list span").size() < 21) {
            element = $(data.follower);
            element.hide();
            followers.find(".friend_list").append(element);
            element.fadeIn("slow");
          }
          if (data.followers_count) {
            followers.find(".count").html(data.followers_count);
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

    // The type of what's being followed
    var entryType = link.attr("data-entry-type");

    return {
      success: function (data) {
        var followers =
          $("#sidebar .followers[data-entry-type=" + entryType + "]");
        if (followers.size() > 0) {
          if (data.user_id) {
            var element = followers.
              find("[data-user-id=" + data.user_id + "]");
            element.fadeOut("slow", function () { element.remove(); });
          }
          if (data.followers_count) {
            followers.find(".count").html(data.followers_count);
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
