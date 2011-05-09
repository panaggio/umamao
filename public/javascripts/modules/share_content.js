$(document).ready(function() {
  // Close modal boxes.
  $(".modal .close").live("click", function () {
    $.colorbox.close();
    return false;
  });

  $("#body").live("keyup", function() {
    var t = $(this);
    var len = t.val().length;
    var maxlen = t.attr('data-maxlength');
    var charcount = t.closest("form").find('.charcount');
    var submit = $(".modal :submit");
    var charsleft = charcount.find('.charsleft');
    var charcount_text = charcount.find('span:last');
    cl = maxlen - len;

    //TODO: internationalize
    if (cl >= 0) {
      if (cl > 1 || cl == 0)
        charcount_text.html("caracteres restantes");
      else
        charcount_text.html("caracter restante");
      charcount.removeClass("negative-counter");
      submit.removeAttr('disabled');
    }
    else {
      if (cl == -1)
        charcount_text.html("caracter excedente");
      else
        charcount_text.html("caracteres excedentes");
      charcount.addClass("negative-counter");
      submit.attr('disabled', 'disabled');

      cl = -cl;
    }

    charsleft.html(cl);
  });

  // Open modal box to share content.
  Utils.clickObject(".share .facebook, .share .twitter", function () {
    return {
      success: function (data) {
        Utils.modal({html: data.html});
      },

      error: function (data) {
        if (data.status == "needs_connection") {
          Utils.modal({html: data.html});
        }
      }
    };
  });

  $(".tab-share-popup").live("click", function(event) {
    li = $(this).closest("li");
    $('.modal .current').removeClass("current");
    li.addClass("current");
    $('#share_on_'+ li.attr('data')).addClass("current");
    return false;  });
});
