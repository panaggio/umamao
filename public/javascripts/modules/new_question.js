
$(document).ready(function() {
  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

});
