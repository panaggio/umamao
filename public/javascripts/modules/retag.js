$(document).ready(function() {
  $('#retag').live('click',function(){
    var link = $(this);
    $.ajax({
      dataType: "json",
      type: "GET",
      url : link.attr('href'),
      extraParams : { 'format' : 'js'},
      success: function(data) {
        if(data.success){
          var oldList = link.parents(".topic-list");
          oldList.find('.topic, .retag').hide();
          oldList.after(data.html);
          initAutocomplete();
          $('.autocomplete_for_tags');
        } else {
            showMessage(data.message, "error");
            if(data.status == "unauthenticate") {
              window.location = "/users/login";
            }
        }
      }
    });
    return false;
  });

  $('.retag-form').live('submit', function() {
    form = $(this);
    var button = form.find('input[type=submit]');
    button.attr('disabled', true);
    $.ajax({url: form.attr("action")+'.js',
            dataType: "json",
            type: "POST",
            data: form.serialize()+"&format=js",
            success: function(data, textStatus) {
                if(data.success) {
                    var topicList = form.siblings(".topic-list");
                    topicList.find('.topic').remove();
                    data.topics.forEach(function (topic) {
                      var topicLink = $("<a />").attr("href", topic.url).
                                            text(topic.title);
		      topicList.prepend($('<li class="topic" />').append(topicLink));
		    });
                    form.remove();
                    $('.retag').show();
                    showMessage(data.message, "notice");
                } else {
		  showMessage(data.message, "error");
                  if(data.status == "unauthenticate") {
                    window.location = "/users/login";
                    }
                }
            },
            error: manageAjaxError,
            complete: function(XMLHttpRequest, textStatus) {
              button.attr('disabled', false);
            }
    });
    return false;
  });

  $('.cancel-retag').live('click', function(){
      var topicList = $(this).parent().siblings(".topic-list");
      topicList.find('.topic, .retag').show();
      topicList.siblings('form').remove();
      return false;
  });
});