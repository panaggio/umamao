function signUpAjaxRequest() {
    var form = $(this).parents("form");
    $("#affiliation_submit").fadeOut("slow", function(){$("#ajax-loader").removeClass('hidden');});
    $("input#affiliation_email").attr("readonly", "readonly");
    
    return {
	  url: "/affiliations?format=js",
      data: form.serialize(),
      complete: function(){
		                    $("#ajax-loader").addClass('hidden');
		                    $("#affiliation_submit").fadeIn("slow");
		                    $("input#affiliation_email").removeAttr("readonly") ;
		                  }
    };
 }
