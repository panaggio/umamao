$(document).ready(function() {
  $("#signup-wizard .topic-title a").attr("target", "_blank");

  $(".close-link").click(function(event) {
    event.preventDefault();
    var link = $(this);
    $.ajax({
      url: $(this).attr("href"),
      dataType: "js",
      type: "GET",
      success: function(data) {
        $('#getting_started_div').html('')
      }});
    });

});
