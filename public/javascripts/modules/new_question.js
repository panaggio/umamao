$(document).ready(function() {
  initTopicAutocompleteForForms('question');

  initQuestionAutocomplete();

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  function imageDialogText(makeLinkMarkdown) {
    Utils.modal({inline: true, href: "#image-prompt"});

    $("#new_content_image").bind("ajax:remotipartSubmit",
                                 function (event, xhr, settings) {
      var link = $(this).find("input[name=link]").val();
      settings.resetForm = true;
      if (link != "") {
        makeLinkMarkdown(link);
        xhr.abort("aborted");
        $.colorbox.close();
        return false;
      }
      return true;
    }).bind("ajax:success", function (event, data) {
      $("#ask_question").after(data.html);
      makeLinkMarkdown(data.url);
    }).bind("ajax:complete", function (event) {
      $.colorbox.close();
    });
  };

  $("#question-input").wmdMath({preview: "question-preview",
                                imageDialogText: imageDialogText});

});
