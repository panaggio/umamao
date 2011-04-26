var selector = '#profile-display .delete-suggestion a, #profile-display .refuse-suggestion a';

Utils.clickObject(selector, function(){  
  var li = $(this).closest("li");

  return {
    success: function(){
      li.hide(800, function(){
        $(this).remove();
      });         
    }
  };
});
