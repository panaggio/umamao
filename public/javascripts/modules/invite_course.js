$(document).ready(function() {

  $(".student-invitation").live("click", function() {
    var link = $(this);
    $.ajax({
      url: $(this).attr("href"),
      dataType: "json",
      type: "GET",
      success: function(data) {
        if(link.is(".reinvite")){
          showMessage(data.message, "notice");
        }else{
          Utils.modal({html: data.html});
        }
      }
    });

    return false;
  });

});

Utils.clickObject(".invite-button", function () {
  return {

    success: function (data) {
      showMessage(data.message, "notice");
      $.colorbox.close();
      location.reload();
    }

  };
});

Utils.clickObject(".student-suggestion a.follow_link, .student-suggestion a.unfollow_link", function () {
  return {
    type: "POST",
    success: function (data) {
      if(data.success){
        $('#'+data.div_id).replaceWith(data.new_link);
      }
    }

  };
});
