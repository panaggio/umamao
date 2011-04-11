$(document).ready(function() {

  initTopicAutocompleteForForms('question_list');

  $("#new_question_list .initially-hidden").hide();

  // Display/hide question list description when asking a new question.
  $("#new_question_list #show-description").click(function () {
    var link = $(this);
    var description = $("#new_question_list .initially-hidden");
    description.slideDown("slow", function () {
      if (!wmdInit) {
        $("#description-input").wmdMath({preview: "description-preview"});
        wmdInit = true;
      }
    });
    link.fadeOut("slow", function () { link.remove(); });
  });

  // For some reason, WMD throws an exception if its target is hidden.
  // Thus, we'll only initialize it the first time we display the form.
  var wmdInit = false;
});
