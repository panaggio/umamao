$(document).ready(function () {

  var editor = $("form.editor");
  if (editor.length == 0) return true;

  var editorOptions = {
    preview: editor.find(".markdown")[0]
  };

  return true;
});
