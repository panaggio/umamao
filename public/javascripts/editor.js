// Initializes the editor.

$(document).ready(function () {

  var editor = $("form.editor");
  if (editor.length == 0) return true;

  var initialized = false;

  var editorOptions = {
    preview: editor.find(".markdown")[0]
  };

  if ($("#image-prompt").length > 0) {
    editorOptions.imageDialogText = Utils.enableImageUploadsOnEditor();
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
