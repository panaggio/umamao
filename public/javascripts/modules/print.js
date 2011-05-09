$(document).ready(function() {
  Utils.modal({inline: true, href: "#wait-to-print"});

  MathJax.Hub.Queue(function () {
    $.colorbox.close();
    $("#wait-to-print").hide();
    print();
  });
});
