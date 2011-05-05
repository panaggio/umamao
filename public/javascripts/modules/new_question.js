$(document).ready(function() {
  initTopicAutocompleteForForms('question');

  initQuestionAutocomplete();

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  $("#question-input").wmdMath({
    preview: "preview-area",
    needsMathRefresh: function(){
      return $("#preview-command #view").css('display') == 'none';
    }
  });
});
