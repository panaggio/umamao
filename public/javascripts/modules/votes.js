$(document).ready(function() {
  Utils.clickObject("form.vote_form", function () {
    var btn_name = $(this).find("button").attr("name");
    var form = $(this);

    return {
      success: function (data) {
        form.find(".votes_average").text(data.average);
        if (data.vote_state == "deleted") {
          form.find("button[name=vote_down] img").attr("src", "/images/to_vote_down.png");
          form.find("button[name=vote_up] img").attr("src", "/images/to_vote_up.png");
        }
        else {
          if (data.vote_type == "vote_down") {
            form.find("button[name=vote_down] img").attr("src", "/images/vote_down.png");
            form.find("button[name=vote_up] img").attr("src", "/images/to_vote_up.png");
          } else {
            form.find("button[name=vote_up] img").attr("src", "/images/vote_up.png");
            form.find("button[name=vote_down] img").attr("src", "/images/to_vote_down.png");
          }
        }
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          Utils.redirectToSignIn();
        }
      }

    };
  });
});
