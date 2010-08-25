function setupWmd(name) {
    var form = document.getElementById(name + "-form");
    var preview = document.getElementById(name + "-preview");
    var panes = {input:form, preview:preview, output:null};
    var previewManager = new Attacklab.wmd.previewManager(panes);
    var editor = new Attacklab.wmd.editor(form, previewManager.refresh);
}