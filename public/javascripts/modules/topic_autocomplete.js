function initTopicAutocompleteForForms(fieldName) {
  var topicBox = new TopicAutocomplete("#topic-autocomplete-input",
                                       "#topic-autocomplete-suggestions");
  var topicsUl = $("ul.topic-list");

  $(".add-topic").live("click", function() {
    if (topicBox.isActive)
      topicBox.returnDefault();
    return false;
  });

  $(".topic .remove").live("click", function () {
    $(this).closest("li").remove();
    return false;
  });

  // Classifies the current content under topic named title.
  topicBox.action = function (title) {
    var topicLi = '<li><div class="topic"><span class="topic-title">${title}</span>' +
      '<a class="remove" href="#">✕</a></div><input type="hidden" ' +
      'name="${fieldName}[topics][]" value="${title}" /></li>';
    topicsUl.append($.tmpl(topicLi, {title: title, fieldName: fieldName}));
    topicBox.clear();
  };
}
