// Utility functions.

window.Utils = {

  // Escapes every character in a string that has a special meaning in a
  // regular expression.
  // TODO: actually test this.
  escapeRegExp: function (string) {
    return string.replace(/[\{\}\(\)\[\]\.\+\*\?\$\^\\]/g, "\\$&");
  },

  // Makes A inherit from B.
  // This extension is static, so later changes to B won't be propagated.
  extend: function (A, B) {
    A.prototype = $.extend({}, B.prototype, A.prototype);
  },

  // Adds parameters to an url.
  buildUrl: function (url, params) {
    return url + (url.match(/\?/) ? "&" : "?") + params;
  }

};
