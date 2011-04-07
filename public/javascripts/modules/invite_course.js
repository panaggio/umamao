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

// Workaroud to get .follow_link's to work properly
$('a[data-confirm], a[data-method], a[data-remote]').die("click.rails");
