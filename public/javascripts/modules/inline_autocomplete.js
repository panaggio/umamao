function InlineAutocomplete (inputField, itemBoxContainer) {
  AutocompleteBox.call(this, inputField, itemBoxContainer);
}

function findAutocompleteText(element) {
  var val = $(element).val();

  var e = element.selectionEnd;
  var s;
  for (s=e+1; s>1 && val[s-1] != '@'; s--);
  $(element).attr("data-s", s);
  $(element).attr("data-e", e);
}

function matchAutocompleteText(element) {
  var el = $(element);
  var val = $(element).val();
  var s = el.attr("data-s");
  var e = el.attr("data-e");
  return val.substring(s,e);
}

function updateAutocompleteText(element, str, url) {
  var el = $(element);
  var val = el.val();
  var s = el.attr("data-s");
  var e = el.attr("data-e");

  $(element).val(
    val.substring(0,s-1) + "[" + str + "]" + "(" + url + ") " +
    val.substring(e,val.length)
  );

  //HACK (initial substring + str + url + '[]' + '()')
  var pos = parseInt(s) + str.length + url.length + 4;
  element.focus();
  element.setSelectionRange(pos, pos); 
}

InlineAutocomplete.prototype = {
  // Builds an item for this box.
  makeItem: function (data) {
    var item = new Item(data);
    var me = this;
    item.click = function () {
      me.action(data);
    };
    return item;
  },

  makeRequest: function (query) {
    var addOnNoExactMatch = this.addOnNoExactMatch;
    var callback = this.requestCallback();
    var input = this.input;
    var request = $.ajax({
      url: this.url,
      dataType: "jsonp",
      jsonp: "json.wrf",
      data: {q: "title:" + Utils.solrEscape(query)},
      success: function (data) {
        var docs = data.response.docs;
        var hasExactMatch = false;
        docs.forEach(function (doc) {
          if (doc.title == query) hasExactMatch = true;
        });
        if (addOnNoExactMatch && !hasExactMatch) {
          docs.push({
            title: input.val(),
            entry_type: "Topic",
            question_count: "0"
          });
        }
        callback(docs);
      }
    });
    return request;
  },

  // Populates the suggestion box when data is received.
  processData: function (data) {
    var items = [];
    var me = this;
    data.forEach(function (it) {
      items.push(me.makeItem(solrConversion(it)));
    });
    return items;
  },

  action: function (data) {
    var input = this.input;
    updateAutocompleteText(input[0], data.title, data.url);
    input.attr("autocomplete", "off").
      attr("data-s", "NaN").attr("data-e", "NaN");
    this.itemBox.hide();
  },
              
  initInputField: function() {
    var box = this;
    var itemBox = this.itemBox;
    var input = this.input;
    input.attr("autocomplete", "off").
      keydown(function (e) {
        if (input.attr("autocomplete") == "on") {
          switch (e.keyCode) {
          case 38: // up
            e.preventDefault();
            itemBox && itemBox.moveUp();
            break;
          case 40: // down
            e.preventDefault();
            itemBox && itemBox.moveDown();
            break;
          case 13: // return
            if (itemBox && itemBox.isSelected()) {
              itemBox.click();
            } else if (box.returnDefault) {
              box.returnDefault();
            }
            e.preventDefault();
            break;
          case 9: // tab
            if (box.activateWithTab && itemBox && itemBox.isSelected()) {
              e.preventDefault();
              itemBox.click();
            }
            break;
          case 8: // backspace
            if (input.attr("data-s") != input.attr("data-e"))
              break;
          case 27: // escape
            if ($(this).val() == "") {
              $(this).addClass("inactive");
              $(this).val(box.startText);
                box.isActive = false;
            }
            if (!box.selectionClicked && itemBox) {
              itemBox.hide();
            }

            if (box.interval) {
              clearInterval(box.interval);
              box.interval = null;
            }

            input.attr("autocomplete", "off");
            box.abortRequest();
            itemBox && itemBox.hide();
            break;
          }
        }
      }).keyup(function (e) {
        if (input.attr("autocomplete") == "off" && e.keyCode == 50) { // @
          if (!box.isActive) {
            box.isActive = true;
            $(this).removeClass("inactive");
          } else if ($(this).val() != "" && itemBox) {
            itemBox.show();
          }

          //TODO: Position itemBox next to @

          if (!box.interval && box.url) {
            box.interval = setInterval(function () {
              box.fetchData(matchAutocompleteText(input[0]));
            }, box.delay);
          }

          input.attr("autocomplete", "on");
        }
        
        if (input.attr("autocomplete") == "on" &&
          ((e.keyCode >= 65 && e.keyCode <= 90) ||
           e.keyCode == 16 || e.keyCode == 32 || e.keyCode == 8)
        ) {
          findAutocompleteText(input[0]);
        }
      });
  }
}

Utils.extend(InlineAutocomplete, AutocompleteBox);

function initInlineAutocomplete() {
  new InlineAutocomplete(
    $("form.editor textarea"), $("#inline-autocomplete-list")
  );

  $(".comment_text_area").each( function () {
    new InlineAutocomplete($(this), $("#" + this.id + "_list"));
  });
}

$(document).ready( function () {
  initInlineAutocomplete();
});
