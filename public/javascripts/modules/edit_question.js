$(function () {
  $("#question-input").wmdMath({
     preview: "preview-area",
     needsMathRefresh: function(){
                         return $("#preview-command #view").css('display') == 'none';
     }});
});
