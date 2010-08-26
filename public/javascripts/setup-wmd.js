/*
 * This is a helper function to setup textarea's with the WMD editor.
 * It receives a base name and finds the related elements inside the
 * document, calling the related WMD functions on them. It uses the
 * following name convention: <name>-form is the id of the textarea
 * element where we edit stuff, and <name>-preview is the id of the
 * div element where the preview must be rendered.
 */

function setupWmd(name) {
  var form = document.getElementById(name + "-form");
  var preview = document.getElementById(name + "-preview");
  var panes = {input:form, preview:preview};
  var previewManager = new Attacklab.wmd.previewManager(panes);
  var editor = new Attacklab.wmd.editor(form, previewManager.refresh);
}
