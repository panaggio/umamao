$(document).ready(function() {
  initTopicAutocompleteForForms('question');

  initQuestionAutocomplete();

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  $("#question-input").wmdMath({preview: "question-preview"});

  $("#new_content_image").bind("ajax:success", function (event, data) {
    $("#ask_question").after(data.html);
  });
});
