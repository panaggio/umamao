
$(document).ready(function() {
  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  // Display/hide question details when asking a new question.
  $("#ask_question #toggle-details").click(function () {
    var details = $("#question-details");
    if (details.is(":hidden")) {
      details.slideDown("slow");
    } else {
      details.slideUp("slow");
    }
    var text = $(this).text();
    var undo = $(this).attr("data-undo");
    $(this).attr("data-undo", text);
    $(this).text(undo);
  });

});
