function initTopicAutocomplete() {
  var topicBox = new TopicAutocomplete("#topic-autocomplete-input",
                                       "#topic-autocomplete-suggestions",
                                       "/topics/autocomplete");
  var topicsUl = $("#ask_question ul.topic-list");

  $(".add-topic").live("click", function() {
    if (topicBox.input.val() != topicBox.startText)
      topicBox.returnDefault();
    return false;
  });

  $("#ask_question a.remove").live("click", function () {
    $(this).closest("li").remove();
    return false;
  });

  // Classifies the current question under topic named title.
  topicBox.action = function (title) {
    var topicLi = '<li><div class="topic"><span class="topic-title">' +
      title + '</span> <a class="remove" href="#">✕</a></div>' +
      '<input type="hidden" name="question[topics][]" value="' +
      title + '" /></li>';
    topicsUl.append($(topicLi));
    topicBox.clear();
  };

}


$(document).ready(function() {

  initTopicAutocomplete();

  // For some reason, WMD throws an exception if its target is hidden.
  // Thus, we'll only initialize it the first time we display the form.
  var wmdInit = false;

  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"));
  });

  // Display/hide question details when asking a new question.
  $("#ask_question #show-details").click(function () {
    var link = $(this);
    var details = $("#question-details");
    details.slideDown("slow", function () {
      if (!wmdInit) {
        $("#question-input").wmdMath({preview: "question-preview"});
        wmdInit = true;
      }
    });
    link.fadeOut("slow", function () { link.remove(); });
  });

});
