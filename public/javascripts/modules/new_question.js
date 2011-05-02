$(document).ready(function() {
  initTopicAutocompleteForForms('question');

  initQuestionAutocomplete();

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  $("#question-input").wmdMath({preview: "question-preview"});

  $("#new_content_image").live("ajax:success", function (data) {
    $("#new_question").after(data.html);
  });
});
