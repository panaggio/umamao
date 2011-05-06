$(document).ready(function() {

  initTopicAutocompleteForForms('question_list');

  $("#new_question_list .initially-hidden").hide();

  // Display/hide question list description when asking a new question.
  $("#new_question_list #show-description").click(function () {
    var link = $(this);
    var description = $("#new_question_list .initially-hidden");
    description.slideDown("slow");
    link.fadeOut("slow", function () { link.remove(); });
  });
});
