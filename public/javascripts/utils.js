// Utility functions.

window.Utils = {

  // Escapes every character in a string that has a special meaning in a
  // regular expression.
  // TODO: actually test this.
  escapeRegExp: function (string) {
    return string.replace(/[\{\}\(\)\[\]\.\+\*\?\$\^\\]/g, "\\$&");
  },

  // Makes A inherit from B.
  // This extension is static, so later changes to B won't be propagated.
  extend: function (A, B) {
    A.prototype = $.extend({}, B.prototype, A.prototype);
  },

  manageAjaxError: function (XMLHttpRequest, textStatus, errorThrown) {
    Utils.showMessage("sorry, something went wrong.", "error");
  },

  showMessage: function (message, t, delay) {
    $("#notifyBar").remove();
    $.notifyBar({
      html: "<div class='message "+t+"' style='width: 100%; height: 100%; padding: 5px'>"+message+"</div>",
      delay: delay||3000,
      animationSpeed: "normal",
      barClass: "flash"
    });
  },

  //  Searches for a given flash_message cookies, call showMessage (above)
  // with its contents and delete it
  showInlineMessage: function() {
    var message = readCookie("flash_error");
    if(message)
      Utils.showMessage(message, "error");
    else {
      message = readCookie("flash_warn");
      if(message)
        Utils.showMessage(message, "warn");
      else {
        message = readCookie("flash_notice");
        if(message)
          Utils.showMessage(message, "notice");	    
      }
    }

    eraseCookie("flash_error");
    eraseCookie("flash_notice");
    eraseCookie("flash_warn");
  },

  // Associates with objects of a given selector AJAX behavior when clicked.
  // prepare is a callback of no arguments that returns parameters to be used in
  // a jQuery.ajax() call. All fields returned by prepare behave exactly as the options
  // expected by jQuery.ajax(), except:
  //
  //   - success: callback to be called if the AJAX request succeeds and the value
  //     of data.success is true.
  //   - error: callback to be called if the AJAX request succeeds but the value
  //     of data.success is false.
  //
  // Both callbacks get passed the return data of the AJAX request. Also, the value
  // of data.message is displayed in an animated box (see Utils.showMessage) if
  // it is present.
  clickObject: function (selector, prepare) {
    $(selector).live("click", function (event) {
      var element = this;
      var settings = prepare.call(element);

      // Basic behavior.
      var ajaxParams = {
        dataType: "json",

        complete: function () {
          $(element).removeAttr("disabled");
          if (settings.complete) settings.complete.call(element);
        },

        error: Utils.manageAjaxError,

        success: function (data) {
          if (data.success) {
            if (settings.success) settings.success.call(element, data);
            if (data.message) Utils.showMessage(data.message, "notice");
          } else {
            if (data.message) Utils.showMessage(data.message, "error");
            if (settings.error) settings.error.call(element, data);
          }
        }
      };

      // Try to guess what to do based on the type and attributes
      // of the element.
      if ($(element).is("a")) {
        ajaxParams.url = settings.url || $(element).attr("href");
        var type = settings.type || $(element).attr("data-method") ||
          "GET";
        var isDelete = type.match(/DELETE/i) ? true : false;

        if (typeof settings.data === "string" ||
            settings.data instanceof String) {
          ajaxParams.data = settings.data + "&format=js";
          if (isDelete) {
            ajaxParams.data += "&method=delete";
          }
        } else if (typeof settings.data === "object") {
          var extraParams = {format: "js"};
          if (isDelete) {
            extraParams.method = "delete";
          }
          ajaxParams.data = $.extend({}, settings.data, extraParams);
        } else {
          ajaxParams.data = isDelete ? "format=js&method=delete" :
            "format=js";
        }
        ajaxParams.type = isDelete ? "POST" : type;
      } else {
        // Assume element belongs to a form.
        var form = $(element).closest("form");
        ajaxParams.url = settings.url || (form.attr("action") + ".js");
        ajaxParams.data = settings.data || form.serialize();
        ajaxParams.type = settings.type || form.attr("method");
      }
      $.ajax(ajaxParams);

      $(element).attr("disabled", "true");

      return false;
    });
  },

  // Wrapper around Colorbox to unify modal's style.
  modal: function (options) {
    var defaultOptions = {
      transition: "none",
      opacity: 0.2,
      close: "",
      overlayClose: false,
      scrolling: false
    };

    options = $.extend({}, options, defaultOptions);

    $.colorbox(options);

    var placedModal = $("#colorbox .modal");

    $.colorbox.resize({width: placedModal.outerWidth()});
  }
};
