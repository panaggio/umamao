$(document).ready(function() {

  // For some reason, WMD throws an exception if its target is hidden.
  // Thus, we'll only initialize it the first time we display the form.
  var wmdInit = false;

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  // Display/hide question details when asking a new question.
  $("#ask_question #toggle-details").click(function () {
    var details = $("#question-details");
    if (details.is(":hidden")) {
      details.slideDown("slow", function () {
        if (!wmdInit) {
          $("#question-input").wmdMath({preview: "question-preview"});
          wmdInit = true;
        }
      });
    } else {
      details.slideUp("slow");
    }
    var text = $(this).text();
    var undo = $(this).attr("data-undo");
    $(this).attr("data-undo", text);
    $(this).text(undo);
  });

});
