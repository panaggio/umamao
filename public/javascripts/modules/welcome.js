$(document).ready(function() {

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
