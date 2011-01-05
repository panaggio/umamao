Utils.clickObject("a.unfollow_link", function () {
  var li = $(this).closest("li");

  return {
    success: function (data) {
      li.remove();
    },

    type: "POST"
  };

});
