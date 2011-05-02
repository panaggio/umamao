function initTopicAutocompleteForForms(classifiable) {
  var topicBox = new TopicAutocomplete("#topic-autocomplete-input",
                                       "#topic-autocomplete-suggestions");
  var topicsUl = $("#classify-ul");

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
    var topicLi = '<li><div class="topic">' + 
      '<span class="topic-title">${title}</span>' +
      '<a class="remove" href="#">✕</a></div><input type="hidden" ' +
      'name="${classifiable}[topics][]" value="${title}" /></li>';
    topicsUl.append($.tmpl(topicLi, {title: title, classifiable: classifiable}));
    topicBox.clear();
  };
}

function initTopicAutocompleteForReclassifying() {
  var topicBox = new TopicAutocomplete("#topic-autocomplete-input",
                                       "#topic-autocomplete-suggestions");

  var topicsUl = $("#classify-ul");

  var classifyUrl = location.pathname;

  // Hides the autocomplete.
  function turnOff() {
    topicsUl.find(".remove").hide();
    $("#topic-autocomplete-input").hide();
    $(".add-topic").hide();
    $(".cancel-reclassify").hide();
    if (topicsUl.find("li").length == 0) {
      $(".reclassify .empty").show();
      $(".reclassify .not-empty").hide();
    } else {
      $(".reclassify .empty").hide();
      $(".reclassify .not-empty").show();
    }
    $(".retag").show();
  }

  // Shows the autocomplete.
  function turnOn() {
    topicsUl.find(".remove").show();
    $("#topic-autocomplete-input").show();
    $(".add-topic").show();
    $(".cancel-reclassify").show();
    $(".retag").hide();
  }

  turnOff();

  $(".reclassify").click(function () {
    turnOn();
    return false;
  });

  $(".add-topic").live("click", function() {
    if (topicBox.isActive)
      topicBox.returnDefault();
    return false;
  });

  $(".cancel-reclassify").live("click", function () {
    turnOff();
    return false;
  });

  $("a.remove", topicsUl).live("click", function () {
    var link = $(this);
    $.getJSON(link.attr("href"), function (data) {
      link.closest("li").remove();
    });
    return false;
  });

  // Classifies the current classifiable entity under topic named title.
  topicBox.action = function (title) {
    $.getJSON(classifyUrl + "/classify?topic=" + encodeURIComponent(title),
              function (data) {
                if (data.success) {
                  topicsUl.find(".retag").before(data.box);
                  Utils.poshytipfy();
                }
              });
    topicBox.clear();
  };

}
