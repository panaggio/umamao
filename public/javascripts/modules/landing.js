function signUpAjaxRequest() {
    var form = $(this).parents("form");

    return {
	  url: "/affiliations?format=js",
      data: form.serialize()
    };
 }
