$(document).ready(function () {
  initTopicAutocompleteForReclassifying();

  // Question submit
  Utils.clickObject("#question-list #new_question_form", function () {
    return {
      success: function (data) {
        var question = $(data.html);
        $("#question-list #questions").append(question);
        question.animate({ backgroundColor: "#ffffcb" },
                         { duration: 100,
                           complete: function () {
                             question.animate({ backgroundColor: "white" }, 2000);
                           }
                         }
        );
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

  // Add new questions
  $("#question-list #add_content .add_questions").click(function () {
    var prefix = $("#question-list h1.navtitle").text().trim();
    var questionTitleInput = $("#question-title-input");
    $("#question-list #add_content").hide();
    $("#question-list #new_question_form").show();
    questionTitleInput.val(prefix + " - ");
    questionTitleInput.focus();
  });

  $("#new_question_form .cancel").click(function () {
    $("#question-list #add_content").show();
    $("#question-list #new_question_form").hide();
  });

  // Add new files
  $("#question-list #add_content .add_files").click(function () {
    $("#question-list #add_content").hide();
    $("#question-list #add_file_form").show();
  });

  $("#add_file_form .cancel").click(function () {
    $("#question-list #add_content").show();
    $("#question-list #add_file_form").hide();
  });
});
