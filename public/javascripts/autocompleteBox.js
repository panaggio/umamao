// Autocomplete boxes used throughout the website.
//
// There are currently two kinds of autocomplete boxes: an all-purpose
// search box, that allows the user to click on each suggested item and
// go to its page, and a topic selection box, used when classifying
// questions and bulk-following topics.
//
// There are three main classes: Item, ItemBox and AutocompleteBox.
// Item takes care of defining how each individual suggested entry is
// displayed and the action to be taken when it is clicked. ItemBox keeps
// track of the currently selected entry and moving between suggestions.
// AutocompleteBox handles keyboard input and contacts the server to
// refresh suggestions.
//
// TODO:
// - Internationalize.
// - Highlight entries where they match the input.
// - Factor this into multiple files that are only loaded when needed.
//

// Data item in an item box.
function Item(data) {
  this.data = data;
  this.html = data.html;
};

Item.prototype = {

  activeItemsClass: "active",
  html: "",
  view: null,
  box: null,

  // Index in the item box.
  index: null,

  // Renders view and binds event handlers.
  buildView: function () {
    var item = this;
    this.view = this.render();
    this.view.click(function () {
      item.click();
      item.box.hide();
    }).mouseover(function () {
      item.box.deactivateSelection();
      item.box.currentItem = item.index;
      item.activate();
    });
    return this.view;
  },

  // Builds the actual DOM element.
  render: function () {
    return $(this.html);
  },

  // Action to be executed when the item is selected.
  click: function () { },

  // Activates the item view.
  activate: function () {
    this.view.addClass(this.activeItemsClass);
  },

  // Deactivates the item view.
  deactivate: function () {
    this.view.removeClass(this.activeItemsClass);
  }

};

// Builds a select-like box with items that can execute
// specific actions when clicked.
function ItemBox(container) {
  this.itemsContainer = $(container);
  this.itemsContainer.hide();
};

ItemBox.prototype = {

  items: [],
  currentItem: null,

  // Changes the set of items in the box.
  //
  // Receives an array of items in the order they should appear.
  setItems: function (items) {
    var box = this;

    // Clears previous items.
    this.itemsContainer.html("");
    this.items = items;
    this.currentItem = null;

    items.forEach(function (item, i) {
      item.box = box;
      item.index = i;
      box.itemsContainer.append(item.buildView());
    });
  },

  // Clears the content of the box.
  clear: function () {
    this.itemsContainer.html("");
    this.items = [];
    this.currentItem = null;
  },

  // Moves the current selection up.
  moveUp: function () {
    if (this.items.length == 0) return;
    if (this.currentItem == null) {
      this.items[this.items.length - 1].activate();
      this.currentItem = this.items.length - 1;
    } else {
      this.items[this.currentItem].deactivate();
      this.currentItem = this.currentItem == 0 ?
        this.items.length - 1 : this.currentItem - 1;
      this.items[this.currentItem].activate();
    }
  },

  // Moves the current selection down.
  moveDown: function () {
    if (this.items.length == 0) return;
    if (this.currentItem == null) {
      this.items[0].activate();
      this.currentItem = 0;
    } else {
      this.items[this.currentItem].deactivate();
      this.currentItem = this.currentItem == this.items.length - 1 ?
        0 : this.currentItem + 1;
      this.items[this.currentItem].activate();
    }
  },

  // Deactivates the current selection.
  deactivateSelection: function () {
    if (this.currentItem != null) {
      this.items[this.currentItem].deactivate();
      this.currentItem = null;
    }
  },

  // Tells whether some entry is selected or not.
  isSelected: function () {
    return this.currentItem == null ? false : true;
  },

  // Runs the "click" event associated with the current active item.
  click: function () {
    if (this.currentItem != null)
      this.items[this.currentItem].click();
  },

  // Hides the box.
  hide: function () {
    this.itemsContainer.hide();
  },

  // Shows the box (i.e. make it visible).
  show: function () {
    this.itemsContainer.show();
  }

};

// Input field that contacts a server to look for suggestions.
function AutocompleteBox(inputField, itemBoxContainer) {

  var box = this;

  this.input = $(inputField);
  this.startText = this.input.val();
  this.itemBox = new ItemBox(itemBoxContainer);
  this.itemBox.itemsContainer.mousedown(function () {
    box.selectionClicked = true;
  });
  this.url = this.input.attr("data-autocomplete-url");
  this.initInputField();

};

AutocompleteBox.prototype = {

  // Whether or not this has been clicked.
  isActive: false,

  startText: "",
  minChars: 2,
  ajaxRequest: null,
  interval: null,
  delay: 400,
  previousQuery: null,

  // Whether or not pressing <tab> should trigger activate an item.
  activateWithTab: false,

  // This is a hack to deal with inconsistencies in the order in which
  // DOM events are fired. Sometimes, the input box will receive focusout
  // and blur events before a clicked item receives any event. Therefore,
  // we need to be careful when hiding the selection box when the input
  // loses focus, since hiding it will prevent it from receiving click
  // events.
  selectionClicked: false,

  // Called when return is pressed but no selection is active.
  returnDefault: null,

  // Binds event handlers to input field.
  initInputField: function () {
    var box = this;
    var itemBox = this.itemBox;
    this.input.attr("autocomplete", "off").
      focus(function () {
        if (!box.isActive) {
          box.isActive = true;
          $(this).removeClass("lighter_text");
          $(this).val("");
        } else if ($(this).val() != "") {
          itemBox.show();
        }
        if (!box.interval) {
          box.interval = setInterval(function () {
                                       box.fetchData(box.input.val());
                                     }, box.delay);
        }
    }).blur(function () {
      if ($(this).val() == "") {
        $(this).addClass("lighter_text");
        $(this).val(box.startText);
        box.isActive = false;
      }
      if (!box.selectionClicked) {
        itemBox.hide();
      }
      if (box.interval) {
        clearInterval(box.interval);
        box.interval = null;
      }
    }).keydown(function (e) {
      $(this).removeClass("lighter_text");
      switch (e.keyCode) {
      case 38: // up
        e.preventDefault();
        itemBox.moveUp();
        break;
      case 40: // down
        e.preventDefault();
        itemBox.moveDown();
        break;
      case 13: // return
        if (itemBox.isSelected()) {
          itemBox.click();
        } else if (box.returnDefault) {
          box.returnDefault();
        }
        e.preventDefault();
        break;
      case 9: // tab
        if (box.activateWithTab && itemBox.isSelected()) {
          e.preventDefault();
          itemBox.click();
        }
        break;
      // ignore [escape] [shift] [capslock]
      case 27:
        box.abortRequest();
        itemBox.hide();
        break;
      }
    });
  },

  // Make an ajax request to fetch the data corresponding to a given query.
  makeRequest: function (query) {
    return $.getJSON(this.url, {q: query}, this.requestCallback());
  },

  // Returns a callback to be executed after the request completes.
  requestCallback: function () {
    var box = this;
    return function (data) {
      if (data) {
        box.itemBox.setItems(box.processData(data));
        box.itemBox.show();
      }
    };
  },

  // Sends an AJAX request for items that match current input,
  // processes and renders them.
  fetchData: function (query) {
    if (query.length < this.minChars ||
       this.previousQuery && this.previousQuery == query) return;
    this.previousQuery = query;
    query = query.replace(Utils.solrSyntaxRegExp, "\\$&");
    this.abortRequest();
    this.ajaxRequest = this.makeRequest(query);
  },

  // Clears current input, hides selection box.
  clear: function () {
    this.itemBox.hide();
    this.itemBox.clear();
    this.input.val("");
    this.abortRequest();
  },

  // Aborts an AJAX request for items.
  abortRequest: function () {
    if (this.ajaxRequest) {
      this.ajaxRequest.abort();
      this.ajaxRequest = null;
    }
  }

};


// Items that have an associated url.
function UrlItem(data) {
  this.data = data;
  this.url = data.url;
  this.html = data.html;
}

UrlItem.prototype = {
  click: function () {
    location.href = this.url;
  }
};

Utils.extend(UrlItem, Item);


// Triggers a full search for questions.
function SearchItem(input) {
  this.query = input.val();
  this.form = input.parent("form");
}

SearchItem.prototype = {

  html: '<li class="search" />',

  render: function () {
    return $(this.html).text('Buscar por perguntas com "' + this.query + '"');
  },

  click: function () {
    window.location.href = '/search?q=' + this.query;
  }

};

Utils.extend(SearchItem, Item);

// Convert the JSON data as returned by solr to the format we expect.
function solrConversion(data) {

  data = $.extend({}, data);

  var makeLi = function (inner) {
    return "<li class=\"autocomplete-entry\">" + inner + "</li>";
  };

  var makeDesc = function (inner) {
    return " <span class=\"desc\">" + inner + "</span>";
  };

  switch (data.entry_type) {
  case "User":
    data.url = "/users/" + data.id;
    data.html = makeLi(data.photo_url + " " +
                       data.title + makeDesc("Usuário"));
    break;
  case "Topic":
    var question = data.question_count == 1 ? " pergunta" : " perguntas";
    data.url = "/topics/" + data.id;
    data.html = makeLi(data.title +
                       makeDesc(data.question_count + question));
    break;
  case "Question":
    data.url = "/questions/" + data.id;
    data.html = makeLi(data.title + makeDesc(data.topic));
    break;
  }

  return data;
}

// The all-purpose search box. Looks for questions, topics and users.
// Clicking a search result will take to the page of the corresponding
// entity. Also, displays an item that when clicked takes the user to the
// search page for questions.
function initSearchBox() {

  var searchBox = new AutocompleteBox("#search-field",
                                      "#search-results");

  $("#search-field").closest("form").find("input[type=submit]").
    click(function () {
      if (!searchBox.isActive) {
        $("#search-field").val("");
        return true;
      }
      return searchBox.isActive;
    });

  searchBox.makeRequest = function (query) {
    var request = $.ajax({
      url: this.url,
      dataType: "jsonp",
      jsonp: "json.wrf",
      data: {q: query},
      success: this.requestCallback()
    });
    return request;
  };

  searchBox.processData = function (data) {
    var items = [];

    data.response.docs.forEach(function (result) {
      items.push(new UrlItem(solrConversion(result)));
    });
    items.push(new SearchItem(this.input));
    return items;
  };

  searchBox.returnDefault = function () {
    var query = searchBox.input.val();
    if (query.match(/\?$/)) {
      searchBox.input.closest("form").submit();
    } else {
      window.location.href = '/search?q=' + query;
    }
  };

};

// Topic autocomplete for several boxes in the website.
function TopicAutocomplete(inputField, itemBoxContainer) {
  AutocompleteBox.call(this, inputField, itemBoxContainer);
}

TopicAutocomplete.prototype = {

  activateWithTab: true,

  // Builds an item for this box.
  makeItem: function (data) {
    var item = new Item(data);
    var me = this;
    item.click = this.itemClicked ||
                   function () {
                     me.action(this.data.title);
                     me.clear();
                   };
    return item;
  },

  makeRequest: function (query) {
    var callback = this.requestCallback();
    var input = this.input;
    var request = $.ajax({
      url: this.url,
      dataType: "jsonp",
      jsonp: "json.wrf",
      data: {q: "title:" + query + " AND entry\\_type:Topic"},
      success: function (data) {
        var docs = data.response.docs;
        var hasExactMatch = false;
        docs.forEach(function (doc) {
          if (doc.title == query) hasExactMatch = true;
        });
        if (!hasExactMatch) {
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

  returnDefault: function () {
    var input = this.input.val();
    if (input.trim() != "") {
      this.clear();
      this.action(input);
    }
  },

  // HACK
  itemClicked: null,

  // Action to be run on topic title or input box value.
  action: null

};

Utils.extend(TopicAutocomplete, AutocompleteBox);

function initTopicAutocompleteForFollowing() {
  var topicBox =
    new TopicAutocomplete("#follow-topics-autocomplete",
                          "#follow-topics-suggestions");

  var topicsUl = $("#followed-topics");

  // Sends to the server a request to follow topic named title.
  topicBox.action = function (title) {
    $.ajax({
      url: "/topics/follow.js?answer=t&title=" + encodeURIComponent(title),
      dataType: "json",
      type: "POST",
      success: function (data) {
        if (data.success) {
          // HACK: avoid duplicating entries.
          topicsUl.find(".title a").
            filter(function () {
                     return $(this).text() == title;
                   }).parents("#followed-topics li").remove();
          topicsUl.prepend(data.html);
          showMessage(data.message, "notice");
        } else {
          showMessage(data.message, "error");
        }
      }
    });
    topicBox.clear();
  };

}
