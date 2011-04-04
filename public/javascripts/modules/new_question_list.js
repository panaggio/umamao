$(document).ready(function() {

  initTopicAutocompleteForForms('question_list');

  // For some reason, WMD throws an exception if its target is hidden.
  // Thus, we'll only initialize it the first time we display the form.
  var wmdInit = false;
});
