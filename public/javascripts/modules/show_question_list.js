$(document).ready(function() {
  initTopicAutocompleteForReclassifying();

  $("#question_body").wmdMath({preview: "question-preview"});

  $("#question-list #new_question_form").hide();

  Utils.clickObject("#question-list #question_submit", function() {
    return {
      success: function(data) {
        var question = $(data.html);
        $("#question-list #questions").append(question);
        MathJax.Hub.Queue(['Typeset', MathJax.Hub, question[0]]);
        $("#new_question_form .editor-input").val("");
        $("#questions .empty").remove();
        var prefix = $("#question-list h1.navtitle").text().trim();
        var questionTitleInput = $("#question-title-input");
        questionTitleInput.val(prefix + " - ");
        questionTitleInput.focus();
        window.location.hash = "form";
      }
    };
  });

  $("#question-list #new_question_link").click(function() {
    $("#question-list #new_question_form").show();
    $("#question-list #new_question_link").hide();
    var prefix = $("#question-list h1.navtitle").text().trim();
    var questionTitleInput = $("#question-title-input");
    if (questionTitleInput.length != 0) {
      questionTitleInput.val(prefix + " - ");
      questionTitleInput.focus();
      window.location.hash = "form";
    }
  });

  console.log(window.location.hash);
  if (window.location.hash == "#form" || window.location.hash == "form") {
    $("#question-list #new_question_link").click();
  }

  $("#new_question_form .cancel").click(function() {
    $("#question-list #new_question_form").hide();
    $("#question-list #new_question_link").show();
    window.location.hash = "";
  });
});
