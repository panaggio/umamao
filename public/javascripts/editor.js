// Initializes the editor.

$(document).ready(function () {

  var editor = $("form.editor");
  if (editor.length == 0) return true;

  function removeImage(address) {
    address = address.replace(/([^/]*)$/, "large_$1");

    // Search for the reference definition.
    var re = "^[ ]{0,3}\\[(\\d+)\\]:[ \t]*\n?[ \t]*<?"
             + address
             + ">?[ \t]*\n?[ \t]*(?:(\n*)[\"(](.+?)[\")][ \t]*)?(?:\n+|$)";
    re = new RegExp(re, "gm");

    var text = editor.find("textarea").val();
    var ref;

    text = text.replace(re, function (wholeMatch, id, link) {
      ref = id;
      return "";
    });

    // Remove all references from text.
    text =
      text.replace(new RegExp("!\\[[^\\]]*\\]\\[" + ref + "\\]", "g"), "");

    editor.find("textarea").val(text);
  }

  function enableImageUploads() {
    $("#content-images .remove")
      .live("ajax:success", function (event, data) {
        $(this).closest(".content_image").slideUp("slow", function () {
          removeImage($(this).find("a:first").attr("href"));
          $(this).remove();
          if ($("#content-images .content_image").length == 0) {
            $("#content-images").addClass("empty");
          }
        });
    });

    var makeLinkMarkdown;

    // Bind form events.
    $("#new_content_image").bind("ajax:beforeSend",
                                 function (event, xhr, settings) {
      $("#image-prompt .waiting").show();

      // For some reason, this is not being done by rails.js
      $("#image-prompt form input[type=submit]").attr("disabled", "disabled");

      settings.resetForm = true;
      return true;
    }).bind("ajax:before ajax:remotipartSubmit", function (event, data) {
      var file = $("#image-prompt input[type=file]").val();
      var link = $("#image-prompt input[type=text]").val();
      if (!file) {
        makeLinkMarkdown(Utils.fixPastingErrors(link));
        $.colorbox.close();
        return false;
      }
      return true;
    }).bind("ajax:success", function (event, data) {
      $("#content-images").append(data.html).removeClass("empty");

      makeLinkMarkdown(data.url);
    }).bind("ajax:complete", function (event) {
      $("#image-prompt .waiting").hide();
      $("#image-prompt form input[type=submit]").removeAttr("disabled");
      $.colorbox.close();
    });

    return function (callback) {
      makeLinkMarkdown = callback;
      $("#image-prompt form").resetForm();
      Utils.modal({inline: true, href: "#image-prompt"});
    };

  }

  function needsMathRefresh() {
    return $("#preview-command #view").css("display") == "none";
  }

  var initialized = false;

  var editorOptions = {
    preview: editor.find(".markdown")[0],
    needsMathRefresh: needsMathRefresh,
    helpLink: "http://umamao.com/topics/4cbefdba79de4f58ea000116",
    helpHoverTitle: "Ajuda na formatação do Umamão"
  };

  if ($("#image-prompt").length > 0) {
    editorOptions.imageDialogText = enableImageUploads();
  }

  if ($(".display-editor").length > 0 && editor.is(":hidden")) {
    $(".display-editor").click(function () {
      // This timeout ensures that this code will only be executed after
      // the corresponding form is displayed. Atempting to turn on WMD before
      // that provokes an error.
      setTimeout(function () {
        if (!initialized) {
          editor.find("textarea").wmdMath(editorOptions);
          initialized = true;
        }
      }, 0);
    });
  } else {
    editor.find("textarea").wmdMath(editorOptions);
  }

  return true;
});
