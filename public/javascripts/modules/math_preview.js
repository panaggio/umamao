$(document).ready(function() {
  $(".show_preview_answer").live("click", function () {
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, "preview-area"]);
    $("#preview-area").slideDown();
    $("#preview-command #view").hide();
    $("#preview-command #hide").css("display", "inline");
    return false;
  });
  $(".hide_preview_answer").live("click", function () {
    $("#preview-area").slideUp();
    $("#preview-command #view").css("display", "inline");
    $("#preview-command #hide").hide();
    return false;
  });
});
